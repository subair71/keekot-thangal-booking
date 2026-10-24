import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/admin/data/booking_export.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

VisitBooking example(
  String day,
  String ref, {
  String name = 'Test Visitor',
  String start = '07:00',
}) => VisitBooking(
  id: ref,
  reference: ref,
  visitorName: name,
  visitorAddress: '12 Test Street, Chavakkad',
  phoneMasked: '+91 ••••• 1234',
  visitorPhone: '+919876541234',
  bookedByRole: 'khadim',
  bookedByName: 'Test Khadim',
  visitDate: day,
  startTime: start,
  endTime: '07:30',
  startAt: 1,
  endAt: 2,
  visitors: 2,
  tokenStart: 3,
  tokenEnd: 4,
  status: 'confirmed',
  qrToken: 'private-token-never-export',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const day = '2030-01-10';
  test('exports only selected day and never includes QR credentials', () async {
    final bookings = [
      example(day, 'KT-001', name: '=HYPERLINK("test") & <name>'),
      example('2030-01-11', 'OTHER-DAY'),
    ];
    final bytes = BookingExport.excel(day, bookings);
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheet = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content,
    );
    expect(sheet, contains('t="inlineStr"'));
    expect(sheet, contains('=HYPERLINK(&quot;test&quot;) &amp; &lt;name&gt;'));
    expect(sheet, isNot(contains('<f>')));
    expect(sheet, isNot(contains('OTHER-DAY')));
    expect(sheet, isNot(contains('private-token')));
    expect(sheet, contains('12 Test Street'));
    expect(sheet, contains('Token numbers'));
    expect(sheet, contains('Visitor Phone Number'));
    expect(sheet, contains('+919876541234'));
    expect(sheet, contains('Booked by'));
    expect(sheet, contains('Test Khadim (Khadim)'));
    expect(sheet, isNot(contains('+91 ••••• 1234')));
    expect(sheet, contains('autoFilter ref="A1:J2"'));
    expect(sheet, contains('3–4'));
    await Directory('build/export-qa').create(recursive: true);
    await File('build/export-qa/bookings.xlsx').writeAsBytes(bytes);
  });
  test('time frame includes its start, excludes its end and other dates', () {
    final data = [
      example(day, 'BEFORE', start: '06:59'),
      example(day, 'START', start: '07:00'),
      example(day, 'INSIDE', start: '08:59'),
      example(day, 'END', start: '09:00'),
      example('2030-01-11', 'OTHER', start: '08:00'),
    ];
    final rows = BookingExport.rows(
      day,
      data,
      startMinute: 420,
      endMinute: 540,
    );
    expect(rows.map((row) => row[1]), ['INSIDE', 'START']);
    final archive = ZipDecoder().decodeBytes(
      BookingExport.excel(day, data, startMinute: 420, endMinute: 540),
    );
    final sheet = utf8.decode(
      archive.findFile('xl/worksheets/sheet1.xml')!.content,
    );
    expect(sheet, contains('7:00 AM to 9:00 AM'));
    expect(sheet, contains('2 bookings'));
    expect(sheet, isNot(contains('BEFORE')));
    expect(sheet, isNot(contains('OTHER')));
  });
  test('all day includes midnight and final minute; invalid ranges fail', () {
    final data = [
      example(day, 'FIRST', start: '00:00'),
      example(day, 'LAST', start: '23:59'),
    ];
    expect(BookingExport.rows(day, data), hasLength(2));
    expect(
      BookingExport.rows(day, data, startMinute: 420, endMinute: 540),
      isEmpty,
    );
    for (final range in [(420, 420), (540, 420), (-1, 540), (0, 1441)]) {
      expect(
        () => BookingExport.rows(
          day,
          data,
          startMinute: range.$1,
          endMinute: range.$2,
        ),
        throwsArgumentError,
      );
    }
    expect(BookingExport.filePeriod(420, 540), '0700-0900');
    expect(BookingExport.filePeriod(0, 1440), 'all-day');
  });
  test('PDF supports empty day and multiple pages of bookings', () async {
    final empty = await BookingExport.pdf(day, []);
    expect(String.fromCharCodes(empty.take(4)), '%PDF');
    final data = List.generate(80, (i) => example(day, 'KT-$i'));
    final bytes = await BookingExport.pdf(day, data);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    await Directory('build/export-qa').create(recursive: true);
    await File('build/export-qa/bookings.pdf').writeAsBytes(bytes);
  });
}
