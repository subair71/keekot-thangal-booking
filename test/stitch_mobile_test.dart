import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/features/home/presentation/mobile_quick_booking.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

import 'fixtures.dart';
import 'quick_booking_test.dart' show HomeBookings;

class ChangingBookings extends HomeBookings {
  bool full = false;
  @override
  Future<Availability> availability(String day) async {
    final a = await super.availability(day);
    if (!full) return a;
    return Availability([
      for (final s in a.slots)
        VisitSlot(
          id: s.id,
          visitDate: s.visitDate,
          startTime: s.startTime,
          endTime: s.endTime,
          startAt: s.startAt,
          endAt: s.endAt,
          remaining: 0,
          capacity: s.capacity,
          status: SlotStatus.full,
        ),
    ], 0);
  }
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
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    HomeBookings bookings, {
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = const Size(375, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          signedIn ? FakeAuth() : FakeAuth(user: null),
        ),
        bookingRepositoryProvider.overrideWithValue(bookings),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KeekotApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> finish(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    await tester.pump();
  }

  testWidgets(
    'mobile live capacity refresh disables selected slot and retains count across navigation',
    (tester) async {
      final repo = ChangingBookings();
      final c = await pump(tester, repo);
      final slot = find.descendant(
        of: find.byType(MobileQuickBooking),
        matching: find.text('10:00 AM'),
      );
      await tester.ensureVisible(slot);
      await tester.tap(slot);
      await tester.pumpAndSettle();
      final selection = c.read(mobileVisitSelectionProvider);
      expect(selection.visitors, 2);
      expect(selection.slotId, isNotNull);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('quick-continue')))
            .onPressed,
        isNotNull,
      );
      repo.full = true;
      c.invalidate(availabilityProvider(selection.date!));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('quick-continue')))
            .onPressed,
        isNull,
      );
      expect(
        find.text(
          'Your selected time is no longer available for this group. Choose another time.',
        ),
        findsOneWidget,
      );
      final router = GoRouter.of(
        tester.element(find.byType(MobileQuickBooking)),
      );
      router.go('/book');
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();
      expect(c.read(mobileVisitSelectionProvider).slotId, selection.slotId);
      expect(c.read(mobileVisitSelectionProvider).visitors, 2);
      expect(tester.takeException(), isNull);
      await finish(tester, c);
    },
  );
  testWidgets(
    'mobile verification retains real draft through anonymous login redirect',
    (tester) async {
      final c = await pump(tester, HomeBookings(), signedIn: false);
      final slot = find.descendant(
        of: find.byType(MobileQuickBooking),
        matching: find.text('10:00 AM'),
      );
      await tester.ensureVisible(slot);
      await tester.tap(slot);
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('quick-continue'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(c.read(draftProvider).slot?.startTime, '10:00');
      expect(c.read(draftProvider).visitors, 2);
      final uri = GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).routeInformationProvider.value.uri;
      expect(uri.path, '/login');
      expect(uri.queryParameters['next'], '/book/confirmation');
      expect(tester.takeException(), isNull);
      await finish(tester, c);
    },
  );
  testWidgets('mobile sections navigate and FAQ permits only one open answer', (
    tester,
  ) async {
    final c = await pump(tester, HomeBookings());
    await tester.tap(find.text('Remembrance'));
    await tester.pumpAndSettle();
    expect(find.text('Programmes & Gatherings').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Etiquette'));
    await tester.pumpAndSettle();
    expect(find.text('Visiting Etiquette').hitTestable(), findsOneWidget);
    final fees = find.text(
      'Are there any fees or donations required for booking?',
    );
    await tester.ensureVisible(fees);
    await tester.tap(fees);
    await tester.pumpAndSettle();
    expect(find.textContaining('Absolutely not.'), findsOneWidget);
    final access = find.text(
      'Can I bring elderly family members or wheelchairs?',
    );
    await tester.ensureVisible(access);
    await tester.tap(access);
    await tester.pumpAndSettle();
    expect(find.textContaining('Absolutely not.'), findsNothing);
    expect(find.textContaining('Yes. Ground-floor'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester, c);
  });
}
