import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/app/bootstrap/providers.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/features/admin/data/slot_closures.dart';
import 'package:keekot_thangal/features/admin/presentation/admin_slots_page.dart';

import 'fixtures.dart';
import 'mobile_route_audit_test.dart' show AuditAdmin;

class ScheduleAdmin extends AuditAdmin {
  final changes = <Map<String, dynamic>>[];
  @override
  Future<void> updateSlots(Map<String, dynamic> change) async {
    changes.add(change);
  }
}

void main() {
  late String day;
  late int now;
  late ScheduleAdmin admin;
  late Map<String, String> savedBlocks;
  late Set<String> closedDays;
  late StreamController<Map<String, String>> updates;

  setUp(() {
    day = VisitClock.today();
    now = VisitClock.epoch(day, '08:00');
    admin = ScheduleAdmin();
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
          bookingRepositoryProvider.overrideWithValue(FakeBookings()),
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
    expect(label('0930', 'Open'), findsOneWidget);

    await mount(tester, key: 'reopened');
    expect(label('0900', 'Blocked'), findsOneWidget);
    savedBlocks = {};
    updates.add(savedBlocks);
    await tester.pumpAndSettle();
    expect(label('0900', 'Open'), findsOneWidget);
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
    expect(find.text('Open'), findsNothing);
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
}
