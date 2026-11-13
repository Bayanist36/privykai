import 'package:flutter/foundation.dart';

import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/core/utils/weekdays.dart';

/// A habit with a weekly schedule.
///
/// `weekdaysMask` uses Monday = bit 0 … Sunday = bit 6. The default is every
/// day, which keeps habits created by the SUK-5 build valid after migration.
/// `reminderMinutes` stores the preferred time of day as minutes since
/// midnight. When `reminderIntervalHours` is set, that time is the start of a
/// repeat window that ends at `reminderWindowEndMinutes` and the habit is
/// reminded every N hours inside it.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.createdAt,
    this.colorKey = defaultColorKey,
    this.weekdaysMask = Weekdays.everyDayMask,
    this.reminderMinutes,
    this.reminderIntervalHours,
    this.reminderWindowEndMinutes = defaultWindowEndMinutes,
    this.completedDates = const <String>[],
  });

  static const String defaultColorKey = 'green';
  static const int allWeekdaysMask = Weekdays.everyDayMask;

  /// Product limit shared by the form and the backup validator.
  static const int maxNameLength = 40;

  /// 22:00 — the default end of a repeat window.
  static const int defaultWindowEndMinutes = 22 * 60;

  static const int minIntervalHours = 1;
  static const int maxIntervalHours = 12;

  /// Guard against a window/interval pair that would schedule hundreds of
  /// alarms; Android caps pending alarms per app.
  static const int maxRemindersPerDay = 24;

  final String id;
  final String name;
  final String iconKey;
  final String colorKey;
  final int weekdaysMask;
  final DateTime createdAt;
  final int? reminderMinutes;

  /// Repeat interval in hours; `null` means a single daily reminder.
  final int? reminderIntervalHours;

  /// Last minute of day (minutes since midnight) that may still remind.
  final int reminderWindowEndMinutes;

  /// Calendar days (`yyyy-MM-dd`) on which the habit was completed.
  final List<String> completedDates;

  bool get hasReminder => reminderMinutes != null;

  /// Whether the habit repeats inside a window instead of once a day.
  bool get isIntervalReminder {
    final interval = reminderIntervalHours;
    return reminderMinutes != null && interval != null && interval > 0;
  }

  /// Reminder times of day in minutes since midnight, ascending.
  ///
  /// A single reminder yields one entry. An interval reminder starts at
  /// [reminderMinutes] and steps by [reminderIntervalHours] until
  /// [reminderWindowEndMinutes] (inclusive), capped at
  /// [maxRemindersPerDay].
  List<int> get reminderTimesOfDay {
    final start = reminderMinutes;
    if (start == null) {
      return const <int>[];
    }
    final interval = reminderIntervalHours;
    if (interval == null || interval <= 0) {
      return <int>[start];
    }
    final end = reminderWindowEndMinutes;
    if (end <= start) {
      return <int>[start];
    }
    final step = interval * 60;
    final times = <int>[start];
    for (
      var minute = start + step;
      minute <= end && times.length < maxRemindersPerDay;
      minute += step
    ) {
      times.add(minute);
    }
    return times;
  }

  bool get isEveryDay => Weekdays.isEveryDay(weekdaysMask);

  /// Whether the habit exists on [date] and the weekday is in its schedule.
  bool isScheduledOn(DateTime date) {
    final day = dateOnly(date);
    return !dateOnly(createdAt).isAfter(day) &&
        Weekdays.includes(weekdaysMask, day);
  }

  bool isCompletedOn(DateTime date) =>
      completedDates.contains(DateKey.from(date));

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Consecutive completed *scheduled* days ending today (or the previous
  /// scheduled day while today is still open). Unscheduled days are skipped
  /// and do not break the streak.
  int currentStreak({DateTime? today}) {
    final completed = completedDates.toSet();
    DateTime? cursor = dateOnly(today ?? DateTime.now());

    if (!isScheduledOn(cursor) || !completed.contains(DateKey.from(cursor))) {
      cursor = _previousScheduledDay(cursor);
    }

    var streak = 0;
    while (cursor != null && completed.contains(DateKey.from(cursor))) {
      streak++;
      cursor = _previousScheduledDay(cursor);
    }
    return streak;
  }

  Habit toggleCompletion(DateTime date) {
    final key = DateKey.from(date);
    final next = <String>{...completedDates};
    if (!next.remove(key)) {
      next.add(key);
    }
    final sorted = next.toList()..sort();
    return copyWith(completedDates: sorted);
  }

  Habit copyWith({
    String? id,
    String? name,
    String? iconKey,
    String? colorKey,
    int? weekdaysMask,
    DateTime? createdAt,
    int? reminderMinutes,
    int? reminderIntervalHours,
    int? reminderWindowEndMinutes,
    bool clearReminder = false,
    bool clearReminderInterval = false,
    List<String>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorKey: colorKey ?? this.colorKey,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      createdAt: createdAt ?? this.createdAt,
      reminderMinutes: clearReminder
          ? null
          : reminderMinutes ?? this.reminderMinutes,
      reminderIntervalHours: clearReminder || clearReminderInterval
          ? null
          : reminderIntervalHours ?? this.reminderIntervalHours,
      reminderWindowEndMinutes:
          reminderWindowEndMinutes ?? this.reminderWindowEndMinutes,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  /// Best consecutive run of completed scheduled days in the whole history.
  int bestStreak({DateTime? today}) {
    final limit = dateOnly(today ?? DateTime.now());
    final completed = <DateTime>[
      for (final key in completedDates)
        if (DateKey.parse(key) != null) DateKey.parse(key)!,
    ]..sort();
    var best = 0;
    var current = 0;
    DateTime? previous;
    for (final day in completed) {
      if (day.isAfter(limit) || !isScheduledOn(day)) {
        continue;
      }
      if (previous != null &&
          _nextScheduledDay(previous)?.isAtSameMomentAs(day) == true) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) {
        best = current;
      }
      previous = day;
    }
    return best;
  }

  /// Previous calendar day that belongs to the schedule, or `null` when the
  /// habit has no scheduled days before [date].
  DateTime? _previousScheduledDay(DateTime date) {
    var cursor = dateOnly(date);
    for (var attempt = 0; attempt < 8; attempt++) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      if (isScheduledOn(cursor)) {
        return cursor;
      }
    }
    return null;
  }

  /// Next calendar day that belongs to the schedule, or `null` when there is
  /// no scheduled day after [date].
  DateTime? _nextScheduledDay(DateTime date) {
    var cursor = dateOnly(date);
    for (var attempt = 0; attempt < 8; attempt++) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      if (isScheduledOn(cursor)) {
        return cursor;
      }
    }
    return null;
  }

  /// Calendar day in local time. Public because statistics and reminder
  /// planning share the same boundary.
  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Habit &&
        other.id == id &&
        other.name == name &&
        other.iconKey == iconKey &&
        other.colorKey == colorKey &&
        other.weekdaysMask == weekdaysMask &&
        other.createdAt == createdAt &&
        other.reminderMinutes == reminderMinutes &&
        other.reminderIntervalHours == reminderIntervalHours &&
        other.reminderWindowEndMinutes == reminderWindowEndMinutes &&
        listEquals(other.completedDates, completedDates);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconKey,
    colorKey,
    weekdaysMask,
    createdAt,
    reminderMinutes,
    reminderIntervalHours,
    reminderWindowEndMinutes,
    Object.hashAll(completedDates),
  );

  @override
  String toString() =>
      'Habit(id: $id, name: $name, weekdaysMask: $weekdaysMask)';
}
