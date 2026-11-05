import '../../../core/utils/visit_clock.dart';

/// A public, dated announcement. Publishing it does not alter bookings.
class HomeNotice {
  const HomeNotice({
    required this.visitDate,
    required this.reason,
    required this.active,
  });

  final String visitDate, reason;
  final bool active;

  static HomeNotice? fromMap(Object? value) {
    if (value is! Map) return null;
    final day = value['visitDate'], reason = value['reason'];
    if (day is! String || reason is! String || reason.trim().isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) return null;
    final parsed = DateTime.tryParse(day);
    if (parsed == null || VisitClock.dayKey(parsed) != day) return null;
    return HomeNotice(
      visitDate: day,
      reason: reason.trim(),
      active: value['active'] == true,
    );
  }

  int get expiresAt => VisitClock.epoch(visitDate, '00:00') + 86400000;
  bool visibleAt(DateTime now) =>
      active && now.millisecondsSinceEpoch < expiresAt;
  String get identity => '$visitDate|$reason';
}
