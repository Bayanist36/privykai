import 'package:intl/intl.dart';

/// Russian labels for the Today screen.
abstract final class DateLabels {
  static String todayEyebrow(DateTime date) {
    final formatted = DateFormat('EEEE, d MMMM', 'ru').format(date);
    if (formatted.isEmpty) {
      return formatted;
    }
    return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
  }

  static String reminderTime(int minutesSinceMidnight) {
    final hours = (minutesSinceMidnight ~/ 60).toString().padLeft(2, '0');
    final minutes = (minutesSinceMidnight % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Short reminder summary for cards and lists.
  ///
  /// A single daily reminder renders as `08:00`; an interval reminder renders
  /// as `Каждые 2 ч, 08:00–22:00`.
  static String reminderSummary(
    int minutesSinceMidnight, {
    int? intervalHours,
    int windowEndMinutes = 22 * 60,
  }) {
    if (intervalHours == null || intervalHours <= 0) {
      return reminderTime(minutesSinceMidnight);
    }
    return 'Каждые $intervalHours ч, '
        '${reminderTime(minutesSinceMidnight)}–'
        '${reminderTime(windowEndMinutes)}';
  }
}
