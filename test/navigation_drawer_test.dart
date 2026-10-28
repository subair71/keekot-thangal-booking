import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/core/widgets/sanctuary_navigation_drawer.dart';
import 'package:keekot_thangal/features/authentication/domain/auth_repository.dart';
import 'package:keekot_thangal/features/notifications/domain/notification_repository.dart';

import 'fixtures.dart';
import 'widget_test.dart' show captureKey, capturePage;

class NavigationNotices implements NotificationRepository {
  NavigationNotices({this.items = const [], this.failDisable = false});
  final List<VisitNotice> items;
  final bool failDisable;
  bool disabled = false;
  @override
  Stream<List<VisitNotice>> notices(String uid) => Stream.value(items);
  @override
  Stream<String> get foregroundMessages => const Stream.empty();
  @override
  Future<bool> enable() async => true;
  @override
  Future<void> disable() async {
    disabled = true;
    if (failDisable) throw StateError('Notification service unavailable');
  }

  @override
  Future<void> markRead(String id) async {}
  @override
  void dispose() {}
}

class NavigationAuth extends FakeAuth {
  bool signedOut = false;
  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

Future<void> openNavigation(
  WidgetTester tester, {
  double width = 375,
  double height = 900,
  double scale = 1,
  String language = 'en',
  AppUser? user = const AppUser('visitor', '+919999999999'),
  bool active = true,
  FakeAuth? auth,
  NavigationNotices? notices,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            auth ?? FakeAuth(user: user),
          ),
          bookingRepositoryProvider.overrideWithValue(
            FakeBookings(items: active ? [sampleBooking()] : []),
          ),
          notificationRepositoryProvider.overrideWithValue(
            notices ??
                NavigationNotices(
                  items: active
                      ? const [
                          VisitNotice(
                            'unread',
                            'Visit reminder',
                            '',
                            'sample',
                            false,
                          ),
                          VisitNotice(
                            'read',
                            'Booking confirmed',
                            '',
                            'sample',
                            true,
                          ),
                        ]
                      : [],
                ),
          ),
        ],
        child: const KeekotApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  AppLanguage.select(
    tester.element(find.byType(SanctuaryMenuButton)),
    language,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('header-menu')));
  await tester.pumpAndSettle();
}

Finder drawerText(String text) =>
    find.descendant(of: find.byType(Drawer), matching: find.text(text));

Future<void> revealNavigation(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('navigation-links')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
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

  for (final spec in [
    (320.0, 'en', 1.0),
    (375.0, 'en', 1.0),
    (430.0, 'ml', 1.0),
    (768.0, 'en', 1.0),
    (1440.0, 'en', 1.0),
    (1920.0, 'en', 1.0),
    (320.0, 'ml', 2.0),
    (1440.0, 'ml', 2.0),
  ]) {
    testWidgets('navigation sheet ${spec.$1} ${spec.$2} scale ${spec.$3}', (
      tester,
    ) async {
      await openNavigation(
        tester,
        width: spec.$1,
        language: spec.$2,
        scale: spec.$3,
      );
      expect(tester.takeException(), isNull);
      final drawer = find.byType(Drawer);
      expect(drawer, findsOneWidget);
      if (spec.$3 == 1 && [375, 430, 1440].contains(spec.$1)) {
        await capturePage(tester, 'navigation_${spec.$1.toInt()}_${spec.$2}');
      }
      final passBadge = drawerText(
        spec.$2 == 'ml' ? translateMalayalam('Active pass') : 'Active pass',
      );
      await revealNavigation(tester, passBadge);
      expect(passBadge, findsOneWidget);
      await revealNavigation(tester, drawerText('1'));
      expect(drawerText('1'), findsOneWidget);
      if (spec.$2 == 'en') {
        for (final text in tester.widgetList<Text>(
          find.descendant(of: drawer, matching: find.byType(Text)),
        )) {
          expect(
            RegExp(
              r'[\u0D00-\u0D7F]',
            ).hasMatch(text.data ?? text.textSpan?.toPlainText() ?? ''),
            false,
          );
        }
      }
      final footer = find.byKey(const ValueKey('navigation-language-en'));
      await revealNavigation(tester, footer);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('close-navigation')));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('drawer language and links preserve booking selection', (
    tester,
  ) async {
    await openNavigation(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SanctuaryNavigationDrawer)),
    );
    final slot =
        (await container
                .read(bookingRepositoryProvider)
                .availability('2030-01-10'))
            .slots
            .first;
    container.read(draftProvider.notifier).select(slot, 3);
    final draft = container.read(draftProvider);
    await tester.tap(find.byKey(const ValueKey('navigation-language-ml')));
    await tester.pumpAndSettle();
    expect(find.text(translateMalayalam('Book a visit')), findsOneWidget);
    expect(find.text('Book a visit'), findsNothing);
    expect(container.read(draftProvider), same(draft));
    await tester.tap(find.byKey(const ValueKey('navigation-language-en')));
    await tester.pumpAndSettle();
    final uri = GoRouter.of(
      tester.element(find.byType(SanctuaryNavigationDrawer)),
    );
    await tester.tap(find.widgetWithText(ListTile, 'My Pass'));
    await tester.pumpAndSettle();
    expect(uri.routeInformationProvider.value.uri.path, '/my-bookings');
    expect(find.byType(Drawer), findsNothing);
    expect(container.read(draftProvider), same(draft));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final user in [
    null,
    const AppUser('visitor', '+919999999999'),
    const AppUser('admin', '+919999999999', admin: true),
    const AppUser(
      'khadim',
      '+919999999999',
      khadim: true,
      permissions: ['gate'],
    ),
  ]) {
    testWidgets(
      'menu permissions and empty badges for ${user?.id ?? 'guest'}',
      (tester) async {
        await openNavigation(tester, user: user, active: false, height: 640);
        expect(find.text('Active pass'), findsNothing);
        expect(drawerText('1'), findsNothing);
        final adminLink = find.widgetWithText(ListTile, 'Administration');
        if (user?.staff == true) await revealNavigation(tester, adminLink);
        expect(adminLink, user?.staff == true ? findsOneWidget : findsNothing);
        final signIn = find.widgetWithText(ListTile, 'Sign in with mobile');
        if (user == null) await revealNavigation(tester, signIn);
        expect(signIn, user == null ? findsOneWidget : findsNothing);
        await revealNavigation(
          tester,
          find.byKey(const ValueKey('navigation-language-en')),
        );
        await tester.pumpAndSettle();
        expect(
          drawerText(testConfig.hoursForDate('2030-01-10')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final failCleanup in [false, true]) {
    testWidgets(
      'sign-out clears the draft with notification cleanup failure: $failCleanup',
      (tester) async {
        final auth = NavigationAuth();
        final notices = NavigationNotices(failDisable: failCleanup);
        await openNavigation(tester, auth: auth, notices: notices);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SanctuaryNavigationDrawer)),
        );
        final slot =
            (await container
                    .read(bookingRepositoryProvider)
                    .availability('2030-01-10'))
                .slots
                .first;
        container.read(draftProvider.notifier).select(slot, 2);
        final signOut = find.widgetWithText(ListTile, 'Sign out');
        await revealNavigation(tester, signOut);
        await tester.tap(signOut);
        await tester.pumpAndSettle();
        expect(auth.signedOut, true);
        expect(notices.disabled, true);
        expect(container.read(draftProvider).slot, isNull);
        expect(find.byType(Drawer), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
