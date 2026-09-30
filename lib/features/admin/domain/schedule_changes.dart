import '../../booking/domain/booking_models.dart';

/// Group adjacent slots, without including unselected gaps.
List<Map<String, dynamic>> scheduleChanges({
  required Set<String> dates,
  required List<VisitSlot> slots,
  required Set<String> selectedStarts,
  required bool wholeDay,
  required bool blocked,
  required String reason,
  int? capacity,
}) {
  final ranges = <Map<String, String>>[];
  for (final slot in slots) {
    if (!selectedStarts.contains(slot.startTime)) continue;
    if (ranges.isNotEmpty && ranges.last['endTime'] == slot.startTime) {
      ranges.last['endTime'] = slot.endTime;
    } else {
      ranges.add({'startTime': slot.startTime, 'endTime': slot.endTime});
    }
  }
  final days = dates.toList()..sort();
  return [
    for (final date in days)
      for (final range in wholeDay ? [<String, String>{}] : ranges)
        {
          'visitDate': date,
          ...range,
          'wholeDay': wholeDay,
          'blocked': blocked,
          'reason': reason.trim(),
          'capacity': ?capacity,
        },
  ];
}
