import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'package:keekot_thangal/app/theme/app_theme.dart';
import 'package:keekot_thangal/core/errors/app_failure.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/home/presentation/home_notice_banner.dart';
import 'package:keekot_thangal/features/notifications/domain/home_notice.dart';

import 'fixtures.dart';
import 'mobile_route_audit_test.dart' show AuditAdmin, AuditNotifications;
import 'widget_test.dart' show captureKey, capturePage;

class NoticeBookings extends FakeBookings {
  HomeNotice? notice;
  final changes = StreamController<BookingConfiguration>.broadcast();

  BookingConfiguration get current => BookingConfiguration.fromMap({
    ...testConfig.toMap(),
    if (notice != null)
      'homeNotice': {
        'visitDate': notice!.visitDate,
        'reason': notice!.reason,
        'active': notice!.active,
      },
  });

  @override
  Stream<BookingConfiguration> watchConfiguration() async* {
    yield current;
    yield* changes.stream;
  }

  void setNotice(HomeNotice? value) {
    notice = value;
    changes.add(current);
  }
}

class NoticeAdmin extends AuditAdmin {
  NoticeAdmin(this.bookings);
  final NoticeBookings bookings;
  int publishes = 0, hides = 0;
  bool fail = false;

  @override
  Future<void> publishHomeNotice(HomeNotice notice) async {
    if (fail) {
      throw const AppFailure('Please check your connection and try again.');
    }
    publishes++;
    bookings.setNotice(notice);
  }

  @override
  Future<void> hideHomeNotice() async {
    hides++;
    bookings.setNotice(
      HomeNotice(
        visitDate: bookings.notice!.visitDate,
        reason: bookings.notice!.reason,
        active: false,
      ),
    );
  }
}

HomeNotice noticeFor(String reason, {String? day}) => HomeNotice(
  visitDate: day ?? VisitClock.today(),
  reason: reason,
  active: true,
);

Future<ProviderContainer> noticeApp(
  WidgetTester tester,
  NoticeBookings bookings, {
  AppUser? user,
  NoticeAdmin? admin,
  double width = 375,
}) async {
  // Integration flows and screenshots use the accessible static presentation.
  // The ticker's movement and looping are exercised in its focused tests.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuth(user: user)),
          bookingRepositoryProvider.overrideWithValue(bookings),
          adminRepositoryProvider.overrideWithValue(
            admin ?? NoticeAdmin(bookings),
          ),
          notificationRepositoryProvider.overrideWithValue(
            AuditNotifications(),
          ),
        ],
        child: const KeekotApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(bookings.changes.close);
  return ProviderScope.containerOf(tester.element(find.byType(KeekotApp)));
}

Future<void> tapNoticeAction(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    for (final font in {
      'Playfair Display': 'PlayfairDisplay.ttf',
      'Plus Jakarta Sans': 'PlusJakartaSans.ttf',
      'Noto Sans Malayalam': 'NotoSansMalayalam.ttf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(rootBundle.load('assets/fonts/${font.value}'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('notice expires at the end of its affected date in India', () {
    final notice = noticeFor('Visits cancelled', day: '2026-11-05');
    expect(notice.visibleAt(DateTime.parse('2026-11-05T18:29:59Z')), isTrue);
    expect(notice.visibleAt(DateTime.parse('2026-11-05T18:30:00Z')), isFalse);
    expect(notice.visibleAt(DateTime.parse('2026-11-04T00:00:00Z')), isTrue);
    expect(
      HomeNotice(
        visitDate: notice.visitDate,
        reason: notice.reason,
        active: false,
      ).visibleAt(DateTime.parse('2026-11-05T10:00:00Z')),
      isFalse,
    );
  });

  test(
    'malformed or empty notices are ignored without breaking booking settings',
    () {
      for (final value in [
        null,
        'invalid',
        {'visitDate': '2026-02-30', 'reason': 'Reason', 'active': true},
        {'visitDate': '2026-11-05', 'reason': '   ', 'active': true},
        {'visitDate': 20261105, 'reason': 'Reason', 'active': true},
      ]) {
        final config = BookingConfiguration.fromMap({
          ...testConfig.toMap(),
          'homeNotice': value,
        });
        expect(config.homeNotice, isNull);
        expect(config.defaultSlotCapacity, testConfig.defaultSlotCapacity);
      }
    },
  );

  for (final width in [375.0, 1280.0]) {
    testWidgets('signed-out home shows live notices at ${width}px', (
      tester,
    ) async {
      final bookings = NoticeBookings()
        ..notice = noticeFor(
          'DEMO · ഇന്നത്തെ സന്ദർശനം മാറ്റിവെച്ചു. Please check before travel.',
        );
      await noticeApp(tester, bookings, width: width);
      expect(find.byKey(const ValueKey('home-notice-banner')), findsOneWidget);
      expect(find.text(bookings.notice!.reason), findsOneWidget);
      expect(
        find.text(VisitClock.dayLabel(bookings.notice!.visitDate)),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await capturePage(tester, 'home_notice_${width.toInt()}');
      bookings.setNotice(noticeFor('Updated reason for visitors'));
      await tester.pumpAndSettle();
      expect(find.text('Updated reason for visitors'), findsOneWidget);
      bookings.setNotice(null);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-notice-banner')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('banner disappears at midnight while Home stays open', (
    tester,
  ) async {
    final bookings = NoticeBookings()
      ..notice = noticeFor('Maintenance', day: '2026-11-05');
    var now = DateTime.parse('2026-11-05T18:29:59Z');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(bookings),
          homeNoticeClockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: HomeNoticeBanner()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('home-notice-banner')), findsOneWidget);
    now = DateTime.parse('2026-11-05T18:30:01Z');
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('home-notice-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await bookings.changes.close();
  });

  testWidgets(
    'admin publishes, revisits and hides a notice from the dashboard',
    (tester) async {
      final bookings = NoticeBookings();
      final admin = NoticeAdmin(bookings);
      final container = await noticeApp(
        tester,
        bookings,
        user: const AppUser('admin', '+919999999999', admin: true),
        admin: admin,
      );
      final router = container.read(routerProvider);
      router.go('/admin');
      await tester.pumpAndSettle();
      await tapNoticeAction(tester, 'home-notice-manage');
      await tapNoticeAction(tester, 'home-notice-publish');
      expect(
        find.text('Enter the reason visitors should see.'),
        findsOneWidget,
      );
      expect(admin.publishes, 0);
      const reason = 'DEMO · Visits cancelled due to urgent maintenance.';
      await tester.enterText(
        find.byKey(const ValueKey('home-notice-reason')),
        reason,
      );
      await tester.pumpAndSettle();
      expect(find.text('Banner preview'), findsOneWidget);
      await tapNoticeAction(tester, 'home-notice-publish');
      expect(admin.publishes, 1);
      expect(bookings.notice!.reason, reason);
      expect(bookings.notice!.visitDate, VisitClock.today());
      expect(find.text('Currently visible on Home'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.text(reason), findsOneWidget);
      router.go('/admin/notices');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('home-notice-reason')),
            )
            .controller!
            .text,
        reason,
      );
      await tapNoticeAction(tester, 'home-notice-hide');
      expect(admin.hides, 1);
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-notice-banner')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed publish reports the error and leaves Home unchanged', (
    tester,
  ) async {
    final bookings = NoticeBookings();
    final admin = NoticeAdmin(bookings)..fail = true;
    final container = await noticeApp(
      tester,
      bookings,
      user: const AppUser('admin', '+919999999999', admin: true),
      admin: admin,
    );
    container.read(routerProvider).go('/admin/notices');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('home-notice-reason')),
      'Draft notice',
    );
    await tapNoticeAction(tester, 'home-notice-publish');
    expect(
      find.text('Please check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('Home notice published.'), findsNothing);
    expect(bookings.notice, isNull);
    expect(admin.publishes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-admin staff cannot manage home notices', (tester) async {
    final bookings = NoticeBookings();
    final container = await noticeApp(
      tester,
      bookings,
      user: const AppUser(
        'staff',
        '+919999999999',
        permissions: ['notices', 'settings'],
      ),
    );
    container.read(routerProvider).go('/admin/notices');
    await tester.pumpAndSettle();
    expect(find.text('Staff access is required'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-notice-publish')), findsNothing);
  });
}
