import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/features/authentication/presentation/auth_page.dart';
import 'package:keekot_thangal/features/booking/presentation/booking_page.dart';
import 'package:keekot_thangal/features/booking/presentation/confirmation_page.dart';
import 'package:keekot_thangal/features/booking/presentation/slot_card.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/my_bookings_page.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/pass_card.dart';
import 'package:keekot_thangal/features/my_bookings/data/pass_download.dart';
import 'fixtures.dart';

final captureKey = GlobalKey();

Future<void> capturePage(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_QA')) return;
  final boundary =
      captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/qa').create(recursive: true);
    await File('build/qa/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  FakeAuth? auth,
  FakeBookings? bookings,
}) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth ?? FakeAuth()),
          bookingRepositoryProvider.overrideWithValue(
            bookings ?? FakeBookings(),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: Scaffold(body: page),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Newsreader': 'Newsreader.ttf',
      'Plus Jakarta Sans': 'PlusJakartaSans.ttf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(rootBundle.load('assets/fonts/${font.value}'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final width in [375, 430, 768, 1024, 1280, 1440, 1920]) {
    testWidgets('home and responsive navigation at ${width}px', (tester) async {
      tester.view.physicalSize = Size(width.toDouble(), 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(FakeAuth()),
              bookingRepositoryProvider.overrideWithValue(FakeBookings()),
            ],
            child: const KeekotApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('A little planning.\nA peaceful visit.'),
        findsOneWidget,
      );
      expect(
        find.byType(NavigationBar),
        width <= 1024 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'home_$width');
      await tester.pumpWidget(const SizedBox());
    });
    testWidgets('slot selection and confirmation fit ${width}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width.toDouble(), 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpPage(tester, const BookingPage());
      expect(find.byType(SlotCard), findsNWidgets(24));
      await tester.tap(find.byType(SlotCard).first);
      await tester.pump();
      expect(find.text('Selected'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'slots_$width');
      await pumpPage(tester, const ConfirmationPage());
      expect(find.text('Booking summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'confirmation_$width');
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('OTP consent, send and code entry states', (tester) async {
    final auth = FakeAuth(user: null);
    await pumpPage(tester, const AuthPage(), auth: auth);
    await tester.tap(find.text('Send verification code'));
    await tester.pump();
    expect(auth.sent, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    expect(auth.sent, isTrue);
    expect(find.text('SMS verification code'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('my bookings has useful empty and confirmed states', (
    tester,
  ) async {
    await pumpPage(tester, const MyBookingsPage());
    expect(find.text('No upcoming bookings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpPage(
      tester,
      const MyBookingsPage(),
      bookings: FakeBookings(items: [sampleBooking()]),
    );
    expect(find.text('View pass'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('pass is readable on 375px screen', (tester) async {
    tester.view.physicalSize = const Size(375, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: PassCard(booking: sampleBooking()),
        ),
      ),
    );
    expect(find.text('Download pass (PDF)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturePage(tester, 'pass_375');
  });
  test('PDF pass renders a long visitor name and secure QR', () async {
    final booking = sampleBooking(
      visitorName: List.filled(20, 'Name').join(' '),
    );
    final bytes = await PassDownload.bytes(booking);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    if (const bool.fromEnvironment('CAPTURE_QA')) {
      await Directory('build/qa').create(recursive: true);
      await File('build/qa/visitor-pass.pdf').writeAsBytes(bytes);
    }
  });
}
