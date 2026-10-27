import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/app.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/features/home/presentation/quick_booking_card.dart';

import 'fixtures.dart';

class HomeBookings extends FakeBookings {
  HomeBookings({this.closed = false});
  final bool closed;
  @override
  Stream<Set<String>> watchClosedDays() =>
      Stream.value(closed ? testConfig.dates().toSet() : <String>{});
  @override
  Future<Availability> availability(String day) async => Availability([
    VisitSlot(
      id: '${day}_1000',
      visitDate: day,
      startTime: '10:00',
      endTime: '10:30',
      startAt: 0,
      endAt: 0,
      remaining: 2,
      capacity: 6,
      status: SlotStatus.available,
    ),
    VisitSlot(
      id: '${day}_1030',
      visitDate: day,
      startTime: '10:30',
      endTime: '11:00',
      startAt: 0,
      endAt: 0,
      remaining: 0,
      capacity: 6,
      status: SlotStatus.blocked,
    ),
  ], 0);
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    HomeBookings bookings,
  ) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuth()),
        bookingRepositoryProvider.overrideWithValue(bookings),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KeekotApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('home selection uses existing draft and confirmation route', (
    tester,
  ) async {
    final container = await pump(tester, HomeBookings());
    final card = find.byType(QuickBookingCard);
    final slot = find.descendant(of: card, matching: find.text('10:00 AM'));
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('quick-continue'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(container.read(draftProvider).slot?.startTime, '10:00');
    expect(find.text('Confirm your visit'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  });

  testWidgets('increasing group beyond live capacity disables continue', (
    tester,
  ) async {
    final container = await pump(tester, HomeBookings());
    final card = find.byType(QuickBookingCard);
    final slot = find.descendant(of: card, matching: find.text('10:00 AM'));
    await tester.ensureVisible(slot);
    await tester.tap(slot);
    final add = find.descendant(
      of: card,
      matching: find.byTooltip('Add one visitor'),
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();
    await tester.tap(add);
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
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  });

  testWidgets('blocked booking window has no active quick booking action', (
    tester,
  ) async {
    final container = await pump(tester, HomeBookings(closed: true));
    expect(
      find.text('No available dates in this booking window.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('quick-continue')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump();
  });
}
