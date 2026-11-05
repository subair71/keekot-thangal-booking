import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/admin/data/slot_closures.dart';
import 'package:keekot_thangal/features/admin/presentation/admin_slots_page.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

import 'fixtures.dart';
import 'mobile_route_audit_test.dart' show AuditAdmin;

class ScheduleAdmin extends AuditAdmin {
  final changes = <Map<String, dynamic>>[];
  @override
  Future<void> updateSlots(Map<String, dynamic> change) async {
    changes.add(change);
  }
}

class ScheduleBookings extends FakeBookings {
  BookingConfiguration config = testConfig;
  final slots = <String, VisitSlot>{};
  int calls = 0;
  bool fail = false;

  @override
  Stream<BookingConfiguration> watchConfiguration() => Stream.value(config);

  @override
  Future<Availability> availability(String day) async {
    calls++;
    if (fail) throw StateError('Availability is offline');
    return Availability(
      const SlotGenerator()
          .generate(day, config)
          .map((slot) => slots[slot.id] ?? slot)
          .toList(),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void setSlot(String day, String time, int remaining, SlotStatus status) {
    final slot = const SlotGenerator()
        .generate(day, config)
        .firstWhere((slot) => slot.startTime == time);
    slots[slot.id] = VisitSlot(
      id: slot.id,
      visitDate: day,
      startTime: time,
      endTime: slot.endTime,
      startAt: slot.startAt,
      endAt: slot.endAt,
      remaining: remaining,
      capacity: 6,
      status: status,
    );
  }
}

void main() {
  late String day;
  late int now;
  late ScheduleAdmin admin;
  late ScheduleBookings bookings;
  late Map<String, String> savedBlocks;
  late Set<String> closedDays;
  late StreamController<Map<String, String>> updates;

  setUp(() {
    day = VisitClock.today();
    now = VisitClock.epoch(day, '08:00');
    admin = ScheduleAdmin();
    bookings = ScheduleBookings();
    savedBlocks = {'${day}_0900': 'Prayer time'};
    closedDays = {};
    updates = StreamController<Map<String, String>>.broadcast();
  });
  tearDown(() => updates.close());

  Future<void> mount(WidgetTester tester, {String key = 'first'}) async {
    await tester.pumpWidget(
      ProviderScope(
        key: ValueKey(key),
        overrides: [
          bookingRepositoryProvider.overrideWithValue(bookings),
          adminRepositoryProvider.overrideWithValue(admin),
          adminScheduleClockProvider.overrideWithValue(
            () => DateTime.fromMillisecondsSinceEpoch(now),
          ),
          closedDaysProvider.overrideWith((ref) => Stream.value(closedDays)),
          adminSlotBlocksProvider.overrideWith((ref, date) async* {
            yield savedBlocks;
            yield* updates.stream;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AdminSlots())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chip(String time) => find.byKey(ValueKey('${day}_$time'));
  Finder label(String time, String status) =>
      find.descendant(of: chip(time), matching: find.text(status));

  testWidgets('saved blocks survive reopening and update without selection', (
    tester,
  ) async {
    await mount(tester);
    expect(label('0900', 'Blocked'), findsOneWidget);
    expect(tester.widget<FilterChip>(chip('0900')).selected, isFalse);
    expect(label('0930', 'Available'), findsOneWidget);

    await mount(tester, key: 'reopened');
    expect(label('0900', 'Blocked'), findsOneWidget);
    savedBlocks = {};
    updates.add(savedBlocks);
    await tester.pumpAndSettle();
    expect(label('0900', 'Available'), findsOneWidget);
    expect(label('0900', 'Blocked'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('whole-day closure marks all upcoming slots blocked', (
    tester,
  ) async {
    closedDays = {day};
    await mount(tester);
    expect(label('0830', 'Blocked'), findsOneWidget);
    expect(label('0900', 'Blocked'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
    expect(chip('0800'), findsNothing);
    expect(chip('0730'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('expiry removes selected slots and excludes them from saving', (
    tester,
  ) async {
    now = VisitClock.epoch(day, '07:59');
    await mount(tester);
    await tester.ensureVisible(chip('0800'));
    await tester.tap(chip('0800'));
    await tester.ensureVisible(chip('0830'));
    await tester.tap(chip('0830'));
    await tester.pump();

    now = VisitClock.epoch(day, '08:00');
    await tester.pump(const Duration(minutes: 1));
    expect(chip('0800'), findsNothing);
    expect(chip('0730'), findsNothing);
    expect(chip('0830'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Maintenance');
    final save = find.widgetWithText(
      FilledButton,
      'Block selected dates / slots',
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(admin.changes, hasLength(1));
    expect(admin.changes.single['startTime'], '08:30');
    expect(admin.changes.single['endTime'], '09:00');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an empty state when every slot has expired', (
    tester,
  ) async {
    now = VisitClock.epoch(day, '19:00');
    await mount(tester);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('No upcoming slots on this date.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('matches full and remaining capacity from booking availability', (
    tester,
  ) async {
    bookings.setSlot(day, '09:30', 0, SlotStatus.full);
    bookings.setSlot(day, '10:00', 3, SlotStatus.available);
    bookings.setSlot(day, '10:30', 6, SlotStatus.blocked);
    bookings.setSlot(day, '11:00', 6, SlotStatus.past);
    await mount(tester);
    expect(label('0930', 'Full'), findsOneWidget);
    expect(label('0930', '0 places left'), findsOneWidget);
    expect(label('1000', 'Available'), findsOneWidget);
    expect(label('1000', '3 places left'), findsOneWidget);
    expect(label('1030', 'Blocked'), findsOneWidget);
    expect(chip('1100'), findsNothing);
    expect(label('0900', 'Blocked'), findsOneWidget);
    expect(label('0900', '12 places left'), findsNothing);
    expect(tester.widget<FilterChip>(chip('0930')).selected, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('polls holds and refreshes immediately on saved slot changes', (
    tester,
  ) async {
    await mount(tester);
    expect(label('0930', 'Available'), findsOneWidget);
    bookings.setSlot(day, '09:30', 0, SlotStatus.full);
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(label('0930', 'Full'), findsOneWidget);

    final calls = bookings.calls;
    bookings.setSlot(day, '09:30', 4, SlotStatus.available);
    updates.add(Map.of(savedBlocks));
    await tester.pumpAndSettle();
    expect(bookings.calls, greaterThan(calls));
    expect(label('0930', 'Available'), findsOneWidget);
    expect(label('0930', '4 places left'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('manual refresh loads current availability', (tester) async {
    await mount(tester);
    bookings.setSlot(day, '09:30', 0, SlotStatus.full);
    await tester.tap(find.text('Refresh availability'));
    await tester.pumpAndSettle();
    expect(label('0930', 'Full'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('availability errors never label generated slots available', (
    tester,
  ) async {
    bookings.fail = true;
    await mount(tester);
    expect(find.text('Available'), findsNothing);
    expect(find.text('We could not load this information.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Block selected dates / slots'),
          )
          .onPressed,
      isNull,
    );
    bookings.fail = false;
    bookings.setSlot(day, '09:30', 0, SlotStatus.full);
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(label('0930', 'Full'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dates outside booking window keep saved closures editable', (
    tester,
  ) async {
    bookings.config = BookingConfiguration.fromMap({
      ...testConfig.toMap(),
      'allowSameDayBooking': false,
    });
    await mount(tester);
    expect(bookings.calls, 0);
    expect(label('0900', 'Blocked'), findsOneWidget);
    expect(label('0930', 'Outside booking window'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
    expect(tester.widget<FilterChip>(chip('0930')).onSelected, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('paused bookings are not shown as available', (tester) async {
    bookings.config = BookingConfiguration.fromMap({
      ...testConfig.toMap(),
      'bookingEnabled': false,
    });
    await mount(tester);
    expect(bookings.calls, 0);
    expect(label('0900', 'Blocked'), findsOneWidget);
    expect(label('0930', 'Bookings are currently paused'), findsOneWidget);
    expect(find.text('Available'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
