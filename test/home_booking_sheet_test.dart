import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'package:keekot_thangal/core/localization/app_language.dart';
import 'package:keekot_thangal/features/booking/presentation/booking_page.dart';
import 'package:keekot_thangal/features/home/presentation/home_booking_sheet.dart';
import 'package:keekot_thangal/features/home/presentation/mobile_quick_booking.dart';
import 'package:keekot_thangal/features/home/presentation/quick_booking_card.dart';

import 'fixtures.dart';
import 'quick_booking_test.dart' show HomeBookings;
import 'widget_test.dart' show captureKey, capturePage;

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    String language = 'en',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuth()),
        bookingRepositoryProvider.overrideWithValue(HomeBookings()),
      ],
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: captureKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const KeekotApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    AppLanguage.select(tester.element(find.byType(Scaffold).first), language);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> open(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('home-booking-open'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  }

  for (final size in [
    const Size(390, 844),
    const Size(768, 900),
    const Size(1280, 900),
  ]) {
    testWidgets('home booking uses the correct layout at ${size.width}', (
      tester,
    ) async {
      final container = await mount(tester, size: size);
      final router = container.read(routerProvider);
      if (size.width >= 768) {
        expect(find.byType(QuickBookingCard), findsOneWidget);
        expect(find.byType(HomeBookingSheet), findsNothing);
        expect(find.text('View all availability'), findsOneWidget);
        router.go('/?section=book');
        await tester.pumpAndSettle();
        expect(find.byType(QuickBookingCard), findsOneWidget);
        expect(find.byType(HomeBookingSheet), findsNothing);
        await capturePage(tester, 'home_inline_booking_${size.width.toInt()}');
        final book = find.text('Book a visit').first;
        await tester.ensureVisible(book);
        await tester.tap(book);
        await tester.pumpAndSettle();
        expect(find.byType(BookingPage), findsOneWidget);
        expect(find.byType(HomeBookingSheet), findsNothing);
        expect(router.routeInformationProvider.value.uri.path, '/book');
        expect(tester.takeException(), isNull);
        await finish(tester, container);
        return;
      }
      expect(find.byType(QuickBookingCard), findsNothing);
      final draft = container.read(draftProvider);
      await open(tester);
      expect(find.byType(HomeBookingSheet), findsOneWidget);
      expect(find.byType(QuickBookingCard), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.text('10:30 AM'), findsNothing);
      await capturePage(tester, 'home_booking_sheet_${size.width.toInt()}');
      await tester.tap(find.byKey(const ValueKey('home-booking-close')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeBookingSheet), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(container.read(draftProvider), same(draft));
      expect(tester.takeException(), isNull);
      await finish(tester, container);
    });
  }

  testWidgets('bottom booking button opens sheet and back returns home', (
    tester,
  ) async {
    final container = await mount(tester);
    await tester.tap(find.byKey(const ValueKey('bottom-navigation-/book')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeBookingSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeBookingSheet), findsNothing);
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/',
    );
    expect(tester.takeException(), isNull);
    await finish(tester, container);
  });

  testWidgets('mobile selection survives dismissing and reopening the sheet', (
    tester,
  ) async {
    final container = await mount(tester);
    await open(tester);
    final slot = find.descendant(
      of: find.byType(MobileQuickBooking),
      matching: find.text('10:00 AM'),
    );
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    final selected = container.read(mobileVisitSelectionProvider);
    await tester.tap(find.byKey(const ValueKey('home-booking-close')));
    await tester.pumpAndSettle();
    await open(tester);
    expect(container.read(mobileVisitSelectionProvider), same(selected));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('quick-continue')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
    await finish(tester, container);
  });

  testWidgets('booking sheet scrolls with large Malayalam text', (
    tester,
  ) async {
    final container = await mount(
      tester,
      size: const Size(375, 667),
      scale: 1.8,
      language: 'ml',
    );
    await open(tester);
    expect(find.text(translateMalayalam('Select date')), findsOneWidget);
    final proceed = find.byKey(const ValueKey('quick-continue'));
    await tester.ensureVisible(proceed);
    await tester.pumpAndSettle();
    expect(proceed.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester, container);
  });

  testWidgets('home booking section link opens the same sheet', (tester) async {
    final container = await mount(tester);
    container.read(routerProvider).go('/?section=book');
    await tester.pumpAndSettle();
    expect(find.byType(HomeBookingSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester, container);
  });
}
