import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/admin/data/booking_export.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

VisitBooking example(String day, String ref, {String name = 'Test Visitor'}) =>
    VisitBooking(
      id: ref,
      reference: ref,
      visitorName: name,
      visitorAddress: '12 Test Street, Chavakkad',
      phoneMasked: '+91 ••••• 1234',
      visitDate: day,
      startTime: '07:00',
      endTime: '07:30',
      startAt: 1,
      endAt: 2,
      visitors: 2,
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
    await Directory('build/export-qa').create(recursive: true);
    await File('build/export-qa/bookings.xlsx').writeAsBytes(bytes);
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
