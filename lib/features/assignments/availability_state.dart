import '../../core/utils/visit_clock.dart';
import 'assignment_repository.dart';

String availabilityNow(Record schedule, List<Record> bookings, {int? clock}) {
  final now = clock ?? DateTime.now().millisecondsSinceEpoch;
  final day = '${schedule['visitDate']}';
  bool contains(dynamic w) =>
      VisitClock.epoch(day, '${w['start']}') <= now &&
      VisitClock.epoch(day, '${w['end']}') > now;
  if (!(schedule['hours'] as List? ?? []).any(contains)) return 'Off duty';
  if (schedule['available'] != true ||
      [
        ...(schedule['breaks'] as List? ?? []),
        ...(schedule['unavailable'] as List? ?? []),
      ].any(contains)) {
    return 'Unavailable';
  }
  final count = bookings
      .where(
        (b) =>
            (b['assignment'] as Map?)?['khadimId'] == schedule['khadimId'] &&
            (b['status'] == 'confirmed' || b['checkedInAt'] != null) &&
            ['Assigned', 'In progress'].contains(serviceLabel(b)) &&
            (b['startAt'] as num) <= now &&
            (b['endAt'] as num) > now,
      )
      .length;
  return count >= (schedule['capacity'] as num? ?? 1) ? 'Busy' : 'Available';
}
