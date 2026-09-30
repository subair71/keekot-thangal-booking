import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/admin/domain/schedule_changes.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'fixtures.dart';

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
