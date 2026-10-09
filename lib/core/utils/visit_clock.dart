import 'package:intl/intl.dart';

abstract final class VisitClock {
  static DateTime now() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  static String today() => DateFormat('yyyy-MM-dd').format(now());
  static String dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  static String dayLabel(String day) =>
      DateFormat('EEE, d MMM yyyy').format(DateTime.parse(day));
  static String timeLabel(String time) {
    final parts = time.split(':');
    return DateFormat(
      'h:mm a',
      'en',
    ).format(DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1])));
  }

  static String? timeValue(String label) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5]\d)\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(label.trim());
    if (match == null) return null;
    final hour =
        int.parse(match[1]!) % 12 +
        (match[3]!.toUpperCase() == 'PM' ? 12 : 0);
    return '${hour.toString().padLeft(2, '0')}:${match[2]}';
  }

  static int epoch(String day, String time) =>
      DateTime.parse('${day}T$time:00+05:30').millisecondsSinceEpoch;
}
