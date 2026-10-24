import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/booking/domain/visitor_phone.dart';
import 'package:keekot_thangal/features/booking/presentation/confirmation_page.dart';
import 'package:keekot_thangal/features/my_bookings/data/pass_download.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/pass_card.dart';

import 'fixtures.dart';

class RecordingBookings extends FakeBookings {
  int confirmations = 0;
  String? submittedPhone;
  @override
  Future<String> confirm(String holdId, String name, String address, {String? visitorPhone}) async {
    confirmations++;
    submittedPhone = visitorPhone;
    return 'sample';
  }
}

Map<String, dynamic> staffBookingData() => {
  'bookingId': 'staff-booking',
  'bookingReference': 'KT-STAFF-TEST',
  'userId': 'khadim-account',
  'visitorName': 'Called Visitor',
  'visitorAddress': '12 Visitor Street, Chavakkad',
  'visitorPhone': '+442079460958',
  'visitorPhoneVerified': false,
  'bookedByUid': 'khadim-account',
  'bookedByRole': 'khadim',
  'bookedByName': 'Test Khadim',
  'phoneNumberMasked': '+44 ••••• 0958',
  'visitDate': '2030-01-10',
  'startTime': '10:00',
  'endTime': '10:30',
  'startAt': 1894269600000,
  'endAt': 1894271400000,
  'visitorCount': 2,
  'status': 'confirmed',
  'qrToken': 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('international number normalization matches backend requirements', () {
    expect(normalizeVisitorPhone(' +44 (20) 7946-0958 '), '+442079460958');
    expect(normalizeVisitorPhone('+91 98765 43210'), '+919876543210');
    for (final invalid in ['', '9876543210', '+0123456789', '+123', '+1234567890123456', '+919876543210 ext 2']) {
      expect(normalizeVisitorPhone(invalid), isNull);
    }
    expect(const AppUser('k', '', khadim: true, permissions: ['gate']).canBookForVisitor, isFalse);
  });

  for (final user in [
    const AppUser('admin-account', '', admin: true),
    const AppUser('khadim-account', '+919111111111', khadim: true, permissions: ['bookings']),
    const AppUser('visitor-account', '+919222222222'),
  ]) {
    testWidgets('confirmation captures visitor contact for ${user.id} and keeps account identity', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bookings = RecordingBookings(), auth = FakeAuth(user: user);
      final router = GoRouter(initialLocation: '/confirm', routes: [
        GoRoute(path: '/confirm', builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: ConfirmationPage()))),
        GoRoute(path: '/book/success/:id', builder: (_, _) => const Scaffold(body: Text('Booking completed'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        bookingRepositoryProvider.overrideWithValue(bookings),
      ], child: MaterialApp.router(theme: buildTheme(), routerConfig: router)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Called Visitor');
      await tester.enterText(find.byType(TextFormField).at(1), '12 Visitor Street');
      final phone = find.byKey(const ValueKey('visitor-phone'));
      final confirm = find.text('Confirm booking');
      if (user.canBookForVisitor) {
        expect(phone, findsOneWidget);
        expect(tester.widget<TextFormField>(phone).controller!.text, isEmpty);
        expect(find.text('Mobile verified'), findsNothing);
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(bookings.confirmations, 0);
        expect(find.text('Enter a valid phone number with country code.'), findsOneWidget);
        await tester.enterText(phone, '123');
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(bookings.confirmations, 0);
        await tester.enterText(phone, '+44 (20) 7946-0958');
      } else {
        expect(phone, findsNothing);
        expect(find.text('Mobile verified'), findsOneWidget);
      }
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(bookings.confirmations, 1);
      expect(bookings.submittedPhone, user.canBookForVisitor ? '+442079460958' : null);
      expect(auth.user, same(user));
      expect(find.text('Booking completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('booking model keeps contact and creator separate, without guessing legacy contacts', () {
    final b = VisitBooking.fromMap(staffBookingData());
    expect(b.visitorPhoneDisplay, '+442079460958');
    expect(b.visitorPhoneVerified, isFalse);
    expect(b.bookedByUid, 'khadim-account');
    expect(b.bookedByLabel, 'Test Khadim (Khadim)');
    final legacy = staffBookingData()..remove('visitorPhone')..remove('bookedByRole')..remove('visitorPhoneVerified');
    expect(VisitBooking.fromMap(legacy).visitorPhoneDisplay, 'Not recorded');
    expect(VisitBooking.fromMap(legacy).bookedByLabel, isEmpty);
  });

  testWidgets('pass displays visitor number and creator in separate labelled fields', (tester) async {
    final b = VisitBooking.fromMap(staffBookingData());
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: buildTheme(), home: Scaffold(body: SingleChildScrollView(child: PassCard(booking: b))))));
    await tester.pumpAndSettle();
    expect(find.text('Visitor Phone Number'), findsOneWidget);
    expect(find.text('+442079460958'), findsOneWidget);
    expect(find.text('Booked by'), findsOneWidget);
    expect(find.text('Test Khadim (Khadim)'), findsOneWidget);
    expect(find.text('+44 ••••• 0958'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('staff confirmation PDFs render with visitor contact, creator, and long names', () async {
    final long = List.filled(20, 'Name').join(' ');
    await Directory('build/qa').create(recursive: true);
    for (final role in ['khadim', 'admin']) {
      final b = VisitBooking.fromMap({...staffBookingData(), 'bookedByRole': role});
      final bytes = await PassDownload.bytes(b);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      await File('build/qa/$role-visitor-pass.pdf').writeAsBytes(bytes);
    }
    final longBytes = await PassDownload.bytes(VisitBooking.fromMap({...staffBookingData(), 'visitorName': long, 'bookedByName': long}));
    await File('build/qa/staff-visitor-pass-long.pdf').writeAsBytes(longBytes);
  });
}
