import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/admin/domain/admin_repository.dart';
import 'package:keekot_thangal/features/admin/presentation/khadim_page.dart';
import 'package:keekot_thangal/features/assignments/assignment_repository.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/booking/presentation/visit_form_state.dart';
import 'package:keekot_thangal/features/booking/presentation/confirmation_page.dart';
import 'package:keekot_thangal/features/home/presentation/media/video_gallery.dart';
import 'package:keekot_thangal/features/notifications/domain/notification_repository.dart';
import 'package:keekot_thangal/core/widgets/components.dart';

import 'assignment_preview_test.dart' show DemoAssignments;
import 'fixtures.dart';
import 'widget_test.dart' show captureKey, capturePage;

class AuditAdmin implements AdminRepository {
  @override
  Future<Map<String, int>> dashboard() async => {
    'bookingsToday': 12,
    'visitorsToday': 24,
    'upcoming': 32,
    'availableSlots': 16,
    'fullSlots': 4,
    'cancelled': 2,
  };
  @override
  Stream<List<VisitBooking>> bookingsForDate(String date) =>
      Stream.value([sampleBooking(visitorName: 'DEMO · Ameen')]);
  @override
  Future<List<VisitBooking>> exportBookingsForDate(String date) async => [
    sampleBooking(),
  ];
  @override
  Future<void> updateSlots(Map<String, dynamic> change) async {}
  @override
  Future<void> setDateHours(Map<String, dynamic> change) async {}
  @override
  Future<void> updateSettings(Map<String, dynamic> settings) async {}
  @override
  Future<void> setBookingStatus(String id, String status) async {}
  @override
  Future<Map<String, dynamic>> validatePass(String token, bool checkIn) async =>
      {'valid': true, 'status': 'completed'};
}

class AuditNotifications implements NotificationRepository {
  @override
  Stream<List<VisitNotice>> notices(String uid) => Stream.value([]);
  @override
  Stream<String> get foregroundMessages => const Stream.empty();
  @override
  Future<bool> enable() async => true;
  @override
  Future<void> disable() async {}
  @override
  Future<void> markRead(String id) async {}
  @override
  void dispose() {}
}

Future<ProviderContainer> auditApp(
  WidgetTester tester,
  String route, {
  String language = 'en',
  double width = 375,
  double scale = 1,
  ValueNotifier<String>? notifier,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final lang = notifier ?? ValueNotifier(language);
  addTearDown(lang.dispose);
  final anonymous = route.endsWith('/login') || route == '/login';
  final khadim = route.startsWith('/khadim') && !anonymous;
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuth(
              user: anonymous
                  ? null
                  : AppUser(
                      khadim ? 'demo-khadim' : 'demo-admin',
                      '+919999999999',
                      admin: !khadim,
                      khadim: khadim,
                      permissions: const [
                        'bookings',
                        'slots',
                        'settings',
                        'gate',
                      ],
                    ),
            ),
          ),
          bookingRepositoryProvider.overrideWithValue(
            FakeBookings(items: [sampleBooking(visitorName: 'DEMO · Ameen')]),
          ),
          adminRepositoryProvider.overrideWithValue(AuditAdmin()),
          notificationRepositoryProvider.overrideWithValue(
            AuditNotifications(),
          ),
          assignmentsRepositoryProvider.overrideWithValue(DemoAssignments()),
          publicPassProvider.overrideWith(
            (ref, id) =>
                Stream.value(sampleBooking(visitorName: 'DEMO · Ameen')),
          ),
          khadimAccountsProvider.overrideWith(
            (ref) => Stream.value([
              {
                'uid': 'demo-khadim',
                'name': 'DEMO · Abdullah',
                'phone': '+91 ••••• 0000',
                'enabled': true,
                'permissions': ['bookings', 'slots', 'settings', 'gate'],
              },
            ]),
          ),
        ],
        child: AppLanguage(
          notifier: lang,
          child: Consumer(
            builder: (context, ref, _) {
              final ml = AppLanguage.of(context) == 'ml';
              final theme = buildTheme();
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                locale: Locale(ml ? 'ml' : 'en'),
                supportedLocales: const [Locale('en'), Locale('ml')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: mobileSanctuaryTheme(
                  ml
                      ? theme.copyWith(
                          textTheme: theme.textTheme.apply(
                            fontFamily: 'Noto Sans Malayalam',
                          ),
                        )
                      : theme,
                ),
                routerConfig: ref.watch(routerProvider),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: Column(
                    children: [
                      const Material(
                        color: AppColors.brass,
                        child: SafeArea(
                          bottom: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text(
                                'DEMO · Test data only',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: child!),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Consumer).first),
  );
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    for (final font in {
      'Playfair Display': 'PlayfairDisplay.ttf',
      'Plus Jakarta Sans': 'PlusJakartaSans.ttf',
      'Noto Sans Malayalam': 'NotoSansMalayalam.ttf',
    }.entries) {
      await (FontLoader(
        font.key,
      )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  const routes = [
    '/',
    '/login',
    '/admin/login',
    '/khadim/login',
    '/book',
    '/book/confirmation',
    '/book/success/sample',
    '/my-bookings',
    '/booking/sample',
    '/pass/sample',
    '/information',
    '/contact',
    '/notifications',
    '/admin',
    '/admin/bookings',
    '/admin/slots',
    '/admin/settings',
    '/admin/gate',
    '/admin/khadims',
    '/admin/assignments',
    '/admin/availability',
    '/khadim',
    '/khadim/availability',
    '/access-denied',
    '/missing-page',
  ];
  for (final spec in [
    (320.0, 'en', 1.0),
    (375.0, 'en', 1.0),
    (430.0, 'ml', 1.0),
    (320.0, 'ml', 2.0),
  ]) {
    for (final route in routes) {
      testWidgets('mobile route $route ${spec.$1} ${spec.$2} scale ${spec.$3}', (
        tester,
      ) async {
        await auditApp(
          tester,
          route,
          width: spec.$1,
          language: spec.$2,
          scale: spec.$3,
        );
        expect(tester.takeException(), isNull);
        if (spec.$1 == 375 || spec.$1 == 430) {
          await capturePage(
            tester,
            'redesign_${route == '/' ? 'home' : route.substring(1).replaceAll('/', '-')}_${spec.$2}',
          );
        }
        // Visit the rest of each page, including settings and form actions.
        final scrollables = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        if (scrollables.evaluate().isNotEmpty) {
          final state = tester.state<ScrollableState>(scrollables.first);
          while (state.position.pixels < state.position.maxScrollExtent) {
            state.position.jumpTo(
              (state.position.pixels + 500).clamp(
                0,
                state.position.maxScrollExtent,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
          if (route == '/pass/sample' && spec.$1 == 375) {
            await capturePage(tester, 'redesign_pass_qr_en');
          }
        }
        expect(find.textContaining('Sanctuary Home'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      });
    }
  }

  testWidgets('language and navigation retain visitor form and selection', (
    tester,
  ) async {
    final lang = ValueNotifier('en');
    final container = await auditApp(
      tester,
      '/book/confirmation',
      notifier: lang,
    );
    final name = find.byType(TextFormField).first;
    await tester.enterText(name, 'DEMO Visitor');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'DEMO Address, Kerala',
    );
    lang.value = 'ml';
    await tester.pumpAndSettle();
    expect(find.text('DEMO Visitor'), findsOneWidget);
    container.read(routerProvider).go('/contact');
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/book/confirmation');
    await tester.pumpAndSettle();
    expect(find.text('DEMO Visitor'), findsOneWidget);
    expect(find.text('DEMO Address, Kerala'), findsOneWidget);
    expect(find.byType(ConfirmationPage), findsOneWidget);
    expect(container.read(visitorFormProvider).name, 'DEMO Visitor');
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery remains English in English mode', (tester) async {
    await auditApp(tester, '/');
    final context = tester.element(find.byType(Scaffold).first);
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: PageContainer(child: VideoGallery())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(RegExp(r'[\u0D00-\u0D7F]').hasMatch(text.data ?? ''), false);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection survives leaving the booking route', (tester) async {
    final container = await auditApp(tester, '/book');
    final add = find.byTooltip('Add one visitor');
    await tester.ensureVisible(add);
    await tester.tap(add);
    final afternoon = find.widgetWithText(ChoiceChip, 'Afternoon');
    await tester.ensureVisible(afternoon);
    await tester.tap(afternoon);
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/contact');
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/book');
    await tester.pumpAndSettle();
    expect(container.read(visitSelectionProvider).visitors, 2);
    expect(tester.widget<ChoiceChip>(afternoon).selected, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible validation follows language without clearing fields', (
    tester,
  ) async {
    final lang = ValueNotifier('en');
    await auditApp(tester, '/contact', notifier: lang);
    await tester.enterText(find.byType(TextFormField).first, 'DEMO Visitor');
    await tester.ensureVisible(find.text('Send message'));
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Please complete this field.'), findsWidgets);
    lang.value = 'ml';
    await tester.pumpAndSettle();
    expect(find.text('Please complete this field.'), findsNothing);
    expect(
      find.text(translateMalayalam('Please complete this field.')),
      findsWidgets,
    );
    expect(find.text('DEMO Visitor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP preview uses the existing verification flow', (
    tester,
  ) async {
    await auditApp(tester, '/login');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.ensureVisible(find.text('Send verification code'));
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    await capturePage(tester, 'redesign_otp_en');
    expect(find.text('Verify your mobile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ml']) {
    testWidgets('OTP and keyboard remain accessible in $language', (
      tester,
    ) async {
      await auditApp(
        tester,
        '/login',
        width: 320,
        language: language,
        scale: 2,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      final send = find.widgetWithText(
        FilledButton,
        language == 'ml'
            ? translateMalayalam('Send verification code')
            : 'Send verification code',
      );
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'capture controls, visitor details, OTP and cancellation dialog',
    (tester) async {
      final container = await auditApp(tester, '/book');
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Afternoon'));
      await tester.pumpAndSettle();
      await capturePage(tester, 'redesign_slots_en');
      container.read(routerProvider).go('/book/confirmation');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      await capturePage(tester, 'redesign_visitor_details_en');
      container.read(routerProvider).go('/pass/sample');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cancel booking'));
      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();
      await capturePage(tester, 'redesign_cancellation_en');
      expect(find.text('Cancel this visit?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
