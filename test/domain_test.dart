import 'package:flutter_test/flutter_test.dart';
import 'package:keekot_thangal/features/booking/domain/booking_models.dart';
import 'package:keekot_thangal/core/utils/visit_clock.dart';
import 'package:keekot_thangal/app/router/app_router.dart';
import 'fixtures.dart';

void main() {
  test('exactly 24 non-overlapping half-hour slots within hours', () {
    final slots = const SlotGenerator().generate('2030-01-10', testConfig);
    expect(slots, hasLength(24)); expect(slots.first.startTime, '07:00'); expect(slots.last.endTime, '19:00');
    for (var i = 0; i < slots.length; i++) { expect(slots[i].endAt - slots[i].startAt, 1800000); if (i > 0) expect(slots[i].startAt, slots[i-1].endAt); }
  });
  test('booking window includes 7 dates and excludes the eighth', () {
    final dates = testConfig.dates(DateTime(2030, 1, 10)); expect(dates, hasLength(7)); expect(dates.last, '2030-01-16');
  });
  test('capacity and IST conversion', () {
    final slot = const SlotGenerator().generate('2030-01-10', testConfig).first;
    expect(slot.accepts(12), isTrue); expect(slot.accepts(13), isFalse); expect(slot.accepts(0), isFalse);
    expect(VisitClock.epoch('2030-01-10', '07:00'), DateTime.utc(2030, 1, 10, 1, 30).millisecondsSinceEpoch);
  });
  test('safe authentication return destination', () {
    expect(safeNext('//evil.test'), '/my-bookings'); expect(safeNext('https://evil.test'), '/my-bookings');
    expect(safeNext('/book/confirmation'), '/book/confirmation');
  });
}
