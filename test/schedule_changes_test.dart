import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/admin/domain/schedule_changes.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';

import 'fixtures.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';

void main() {
  final slots = const SlotGenerator().generate('2030-01-10', testConfig);
  test('nonadjacent selected slots exclude gaps on every selected date', () {
    final changes = scheduleChanges(
      dates: {'2030-01-11', '2030-01-10'},
      slots: slots,
      selectedStarts: {'07:00', '07:30', '09:00'},
      wholeDay: false,
      blocked: true,
      reason: 'Closure',
    );
    expect(changes.length, 4);
    expect(changes[0]['startTime'], '07:00');
    expect(changes[0]['endTime'], '08:00');
    expect(changes[1]['startTime'], '09:00');
    expect(changes[1]['endTime'], '09:30');
    expect(changes[2]['visitDate'], '2030-01-11');
    expect(changes.every((c) => c['blocked'] == true), isTrue);
  });
  test('whole-day reopening produces one change per date', () {
    final changes = scheduleChanges(
      dates: {'2030-01-10', '2030-01-12'},
      slots: slots,
      selectedStarts: {},
      wholeDay: true,
      blocked: false,
      reason: '',
      capacity: 10,
    );
    expect(changes.length, 2);
    expect(
      changes.every(
        (c) =>
            c['wholeDay'] == true &&
            c['blocked'] == false &&
            c['capacity'] == 10,
      ),
      isTrue,
    );
  });
  test('expiry is per date and respects custom visiting hours', () {
    final config = BookingConfiguration.fromMap({
      ...testConfig.toMap(),
      'dateHours': {
        '2030-01-11': {'openingTime': '10:00', 'closingTime': '11:00'},
      },
    });
    final now = VisitClock.epoch('2030-01-10', '10:00');
    final today = upcomingScheduleSlots('2030-01-10', config, now);
    final tomorrow = upcomingScheduleSlots('2030-01-11', config, now);
    expect(today.first.startTime, '10:30');
    expect(tomorrow.map((s) => s.startTime), ['10:00', '10:30']);
    expect(tomorrow.last.endTime, '11:00');

    final changes = [
      for (final day in ['2030-01-10', '2030-01-11'])
        ...scheduleChanges(
          dates: {day},
          slots: upcomingScheduleSlots(day, config, now),
          selectedStarts: {'10:00'},
          wholeDay: false,
          blocked: true,
          reason: 'Closure',
        ),
    ];
    expect(changes, hasLength(1));
    expect(changes.single['visitDate'], '2030-01-11');
    expect(changes.single['startTime'], '10:00');
  });

  test('empty selections never change a schedule', () {
    expect(
      scheduleChanges(
        dates: {'2030-01-10'},
        slots: slots,
        selectedStarts: {},
        wholeDay: false,
        blocked: true,
        reason: 'Closure',
      ),
      isEmpty,
    );
  });
}
