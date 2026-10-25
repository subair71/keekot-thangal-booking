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
import 'package:keekot_thangal/features/admin/presentation/admin_date_hours.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/my_bookings_page.dart';
import 'package:keekot_thangal/features/my_bookings/presentation/pass_card.dart';
import 'package:keekot_thangal/features/my_bookings/data/pass_download.dart';

import 'fixtures.dart';

import 'package:keekot_thangal/core/utils/visit_clock.dart';

final captureKey = GlobalKey();

Future<void> capturePage(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_QA')) return;
  // Wait for image decoding before recording the rendered preview.
  // Widget-test settling alone does not wait for asynchronous asset codecs.
  await tester.runAsync(() async {
    final context = captureKey.currentContext!;
    await precacheImage(
      const AssetImage('assets/brand/maqam-hero.png'),
      context,
    );
    if (context.mounted) {
      await precacheImage(
        const AssetImage('assets/brand/official-logo.png'),
        context,
      );
    }
  });
  await tester.pumpAndSettle();
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
  for (final width in [320, 375, 430, 768, 1024, 1100, 1280, 1440, 1920]) {
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
        find.text('A peaceful place.\nA heartfelt visit.'),
        findsOneWidget,
      );
      expect(
        find.byType(NavigationBar),
        width <= 1200 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'home_$width');
      await tester.ensureVisible(find.text('Videos').first);
      await tester.tap(find.text('Videos').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Questions before you visit').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('How do I reserve a visit?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('follow the steps to verify'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'home_details_$width');
      await tester.ensureVisible(
        find.text('All visit times are in India Standard Time.'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'home_footer_$width');
      await tester.ensureVisible(find.text('Plan my visit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan my visit'));
      await tester.pumpAndSettle();
      expect(find.text('Select your visit'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      await tester.ensureVisible(find.byType(SlotCard).first);
      await tester.tap(find.byType(SlotCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Selected'), findsOneWidget);
      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(continueButton.hitTestable(), findsOneWidget);
      expect(
        tester.widget<FilledButton>(continueButton).focusNode!.hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Your visit'));
      await tester.pumpAndSettle();
      await capturePage(tester, 'slots_$width');
      await pumpPage(tester, const ConfirmationPage());
      expect(find.text('Booking summary'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Address'), findsOneWidget);
      final form = tester.state<FormState>(find.byType(Form));
      form.validate();
      await tester.pump();
      expect(find.text('Enter your address.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'confirmation_$width');
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('mobile home and booking support larger bilingual text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 1100);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final font = FontLoader('Noto Sans Malayalam')
      ..addFont(rootBundle.load('assets/fonts/NotoSansMalayalam.ttf'));
    await font.load();
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
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('language-toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturePage(tester, 'home_malayalam_large_text_375');
    final book = find.text('സന്ദർശനം ബുക്ക് ചെയ്യുക').first;
    await tester.ensureVisible(book);
    await tester.tap(book);
    await tester.pumpAndSettle();
    expect(find.byType(BookingPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(SlotCard).first);
    await capturePage(tester, 'slots_malayalam_large_text_375');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'period filters retain selection and visitor controls precede mobile slots',
    (tester) async {
      tester.view.physicalSize = const Size(375, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpPage(tester, const BookingPage());
      expect(
        tester.getTopLeft(find.text('Number of visitors')).dy,
        lessThan(tester.getTopLeft(find.byType(SlotCard).first).dy),
      );
      await tester.ensureVisible(find.byType(SlotCard).first);
      await tester.tap(find.byType(SlotCard).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Afternoon'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Afternoon'));
      await tester.pumpAndSettle();
      expect(find.byType(SlotCard), findsNWidgets(8));
      await tester.tap(find.widgetWithText(ChoiceChip, 'All times'));
      await tester.pumpAndSettle();
      expect(find.text('Selected'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('admin hours load saved values and default values after reset', (
    tester,
  ) async {
    final today = VisitClock.today();
    final custom = BookingConfiguration.fromMap({
      ...testConfig.toMap(),
      'dateHours': {
        today: {'openingTime': '08:00', 'closingTime': '17:00'},
      },
    });
    final key = GlobalKey();
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: AdminDateHours(key: key, config: custom),
      ),
    );
    expect(find.text('Start: 8:00 AM'), findsOneWidget);
    expect(find.text('End: 5:00 PM'), findsOneWidget);
    expect(find.textContaining('18 complete slots'), findsOneWidget);
    await pumpPage(
      tester,
      SingleChildScrollView(
        child: AdminDateHours(key: key, config: testConfig),
      ),
    );
    expect(find.text('Start: 7:00 AM'), findsOneWidget);
    expect(find.text('End: 7:00 PM'), findsOneWidget);
    expect(find.textContaining('24 complete slots'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturePage(tester, 'admin_date_hours');
    await tester.pumpWidget(const SizedBox());
  });

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
    expect(find.text('TOKEN NUMBERS'), findsNothing);
    expect(find.text('1–2'), findsNothing);
    expect(find.text('Show this pass to entry staff'), findsOneWidget);
    expect(
      find.text('Booking reference: ${sampleBooking().reference}'),
      findsOneWidget,
    );
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
