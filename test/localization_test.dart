import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/booking/presentation/booking_page.dart';

import 'fixtures.dart';
import 'navigation_helpers.dart';

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
  });

  setUpAll(() async {
    final font = FontLoader('Noto Sans Malayalam')
      ..addFont(rootBundle.load('assets/fonts/NotoSansMalayalam.ttf'));
    await font.load();
  });
  test('Malayalam formats counts and dates without altering identifiers', () {
    expect(
      translateMalayalam('12 available time slots'),
      '12 സമയങ്ങൾ ലഭ്യമാണ്',
    );
    expect(translateMalayalam('Mon, 12 Oct 2026'), 'തിങ്കൾ, 12 ഒക്ടോബർ 2026');
    expect(translateMalayalam('2026-10-12'), '2026-10-12');
    expect(
      translateMalayalam('KT-20300110-012345ABCDEF'),
      'KT-20300110-012345ABCDEF',
    );
  });
  for (final width in [375.0, 768.0, 1440.0]) {
    testWidgets('language toggle and booking state at $width', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuth()),
            bookingRepositoryProvider.overrideWithValue(FakeBookings()),
          ],
          child: const KeekotApp(),
        ),
      );
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('header-menu'));
      await selectDrawerLanguage(tester, 'ml');
      await tester.pumpAndSettle();
      expect(
        find.text('ശാന്തമായ ഒരിടം.\nഹൃദയപൂർവമായ സന്ദർശനം.'),
        findsOneWidget,
      );
      expect(Localizations.localeOf(tester.element(menu)), const Locale('ml'));
      expect(tester.takeException(), isNull);
      final booking = find
          .text(width < 768 ? 'ബുക്കിംഗ്' : 'സന്ദർശനം ബുക്ക് ചെയ്യുക')
          .first;
      await tester.ensureVisible(booking);
      await tester.tap(booking);
      await tester.pumpAndSettle();
      expect(find.byType(BookingPage), findsOneWidget);
      expect(find.text('സന്ദർശനം തിരഞ്ഞെടുക്കുക'), findsOneWidget);
      final state = tester.state(find.byType(BookingPage));
      final add = find.byTooltip('ഒരു സന്ദർശകനെ കൂട്ടുക');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final remove = find.widgetWithIcon(IconButton, Icons.remove);
      expect(tester.widget<IconButton>(remove).onPressed, isNotNull);
      await selectDrawerLanguage(tester, 'en');
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(BookingPage)), same(state));
      expect(find.text('Select your visit'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      // Header shortcuts must work from a different page and within Home.
      for (final item in const [
        ('Videos', 'videos'),
        ('Visitor guide', 'guide'),
        ('Questions before you visit', 'questions'),
      ]) {
        await tester.tap(find.byKey(const ValueKey('header-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, item.$1));
        await tester.pumpAndSettle();
        final uri = GoRouter.of(
          tester.element(menu),
        ).routeInformationProvider.value.uri;
        expect(uri.path, '/');
        expect(uri.queryParameters['section'], item.$2);
        expect(find.byType(Drawer), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
