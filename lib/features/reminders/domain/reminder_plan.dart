import 'package:flutter/foundation.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';

/// Pure reminder math shared by the scheduler and unit tests.
///
/// A weekday index follows the model mask: 0 = Monday, 6 = Sunday.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.weekdayIndex,
    required this.dateTime,
    this.slotIndex = 0,
    this.repeatsWeekly = true,
  });

  final int id;
  final int weekdayIndex;
  final DateTime dateTime;

  /// Position inside the day: 0 for a single daily reminder, 0…N for the
  /// repeats of an interval reminder.
  final int slotIndex;

  /// Whether the scheduler should use a weekly `matchDateTimeComponents`.
  ///
  /// `false` schedules a single occurrence at [dateTime] and is used for the
  /// evening reminder of a fully completed day.
  final bool repeatsWeekly;
}

/// Evening "did you finish your habits?" reminder, configured globally.
@immutable
class EveningReminder {
  const EveningReminder({required this.minutes, this.skipToday = false});

  /// Minutes since midnight.
  final int minutes;

  /// When true, today's occurrence is moved to the next week because every
  /// habit for today is already completed. Other weekdays keep their slot.
  final bool skipToday;

  EveningReminder copyWith({int? minutes, bool? skipToday}) {
    return EveningReminder(
      minutes: minutes ?? this.minutes,
      skipToday: skipToday ?? this.skipToday,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EveningReminder &&
          other.minutes == minutes &&
          other.skipToday == skipToday;

  @override
  int get hashCode => Object.hash(minutes, skipToday);
}

abstract final class ReminderPlan {
  static const List<String> shortWeekdayLabels = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  static const List<String> weekdayLabels = <String>[
    'понедельник',
    'вторник',
    'среду',
    'четверг',
    'пятницу',
    'субботу',
    'воскресенье',
  ];

  static List<int> weekdayIndexes(int mask) => <int>[
    for (var index = 0; index < 7; index++)
      if ((mask & (1 << index)) != 0) index,
  ];

  static String weekdaysLabel(int mask) {
    if (mask == Habit.allWeekdaysMask) {
      return 'Каждый день';
    }
    final indexes = weekdayIndexes(mask);
    if (indexes.isEmpty) {
      return 'Выберите хотя бы один день';
    }
    return indexes.map((index) => shortWeekdayLabels[index]).join(', ');
  }

  /// Stable positive notification id, independent of the Dart VM hash seed.
  ///
  /// [slotIndex] distinguishes the repeats of an interval reminder inside one
  /// weekday; a single daily reminder always uses slot 0.
  static int notificationId(
    String habitId,
    int weekdayIndex, {
    int slotIndex = 0,
  }) {
    var hash = 0x811C9DC5;
    for (final codeUnit in habitId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final base = hash & 0x1FFFFF;
    final id = ((base * 512) + (weekdayIndex * 64) + slotIndex) & 0x7FFFFFFF;
    return id == 0 ? 1 : id;
  }

  /// Notification id of the global evening reminder for one weekday.
  ///
  /// The `0x7F000000` block never collides with habit ids, which stay below
  /// `0x40000000`.
  static int eveningReminderId(int weekdayIndex) =>
      0x7F000000 + (weekdayIndex & 0x7) + 1;

  /// Next local date/time for a weekly reminder, strictly after [now].
  static DateTime nextOccurrence({
    required DateTime now,
    required int weekdayIndex,
    required int minutesSinceMidnight,
  }) {
    final hour = minutesSinceMidnight ~/ 60;
    final minute = minutesSinceMidnight % 60;
    final targetWeekday = weekdayIndex + 1;
    var dayOffset = (targetWeekday - now.weekday) % 7;
    if (dayOffset < 0) {
      dayOffset += 7;
    }
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + dayOffset,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 7,
        hour,
        minute,
      );
    }
    return candidate;
  }

  /// Pending notifications for [habit]: one per selected weekday for a single
  /// reminder, or one per weekday and per time slot for an interval reminder.
  ///
  /// Pure planning step used by the Android scheduler and unit tests; no
  /// platform API is touched here.
  static List<PlannedReminder> planFor(Habit habit, {required DateTime now}) {
    final times = habit.reminderTimesOfDay;
    if (times.isEmpty || habit.weekdaysMask == 0) {
      return const <PlannedReminder>[];
    }
    return <PlannedReminder>[
      for (final index in weekdayIndexes(habit.weekdaysMask))
        for (var slot = 0; slot < times.length; slot++)
          PlannedReminder(
            id: notificationId(habit.id, index, slotIndex: slot),
            weekdayIndex: index,
            slotIndex: slot,
            dateTime: nextOccurrence(
              now: now,
              weekdayIndex: index,
              minutesSinceMidnight: times[slot],
            ),
          ),
    ];
  }

  /// One evening reminder per weekday when [evening] is set.
  ///
  /// [EveningReminder.skipToday] keeps a fully completed day quiet. The
  /// plugin's `dayOfWeekAndTime` recurrence only compares the weekday and the
  /// time, so shifting the start date by a week still fires today (QA-24-01).
  /// Therefore the suppressed day is scheduled as a one-shot for next week,
  /// while the other weekdays keep their weekly recurrence.
  static List<PlannedReminder> eveningPlan({
    required EveningReminder? evening,
    required DateTime now,
  }) {
    if (evening == null) {
      return const <PlannedReminder>[];
    }
    final todayIndex = now.weekday - 1;
    return <PlannedReminder>[
      for (var index = 0; index < 7; index++)
        _eveningReminder(
          now: now,
          weekdayIndex: index,
          minutes: evening.minutes,
          skipToday: evening.skipToday && index == todayIndex,
        ),
    ];
  }

  static PlannedReminder _eveningReminder({
    required DateTime now,
    required int weekdayIndex,
    required int minutes,
    required bool skipToday,
  }) {
    final first = nextOccurrence(
      now: now,
      weekdayIndex: weekdayIndex,
      minutesSinceMidnight: minutes,
    );
    final isToday =
        first.year == now.year &&
        first.month == now.month &&
        first.day == now.day;
    final skipped = skipToday && isToday;
    return PlannedReminder(
      id: eveningReminderId(weekdayIndex),
      weekdayIndex: weekdayIndex,
      dateTime: skipped
          ? nextOccurrence(
              now: first.add(const Duration(minutes: 1)),
              weekdayIndex: weekdayIndex,
              minutesSinceMidnight: minutes,
            )
          : first,
      repeatsWeekly: !skipped,
    );
  }

  /// Suppresses today's evening nudge when every habit scheduled for [now]
  /// is already completed (or there are no habits at all).
  static EveningReminder? effectiveEvening({
    required EveningReminder? evening,
    required List<Habit> habits,
    required DateTime now,
  }) {
    if (evening == null) {
      return null;
    }
    final today = habits.where((habit) => habit.isScheduledOn(now)).toList();
    final allDone =
        today.isEmpty || today.every((habit) => habit.isCompletedOn(now));
    return evening.copyWith(skipToday: allDone);
  }

  /// Keeps the pending reminders closest to now when a plan is larger than
  /// [limit].
  ///
  /// Some OEMs silently drop alarms above roughly 500 pending notifications.
  /// Sorting by time and cutting the tail preserves the nearest reminders
  /// instead of losing them.
  static const int maxPendingNotifications = 400;

  static List<PlannedReminder> capToLimit(
    Iterable<PlannedReminder> plan, {
    int limit = maxPendingNotifications,
  }) {
    if (limit <= 0) {
      return const <PlannedReminder>[];
    }
    final sorted = plan.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (sorted.length <= limit) {
      return sorted;
    }
    return sorted.sublist(0, limit);
  }

  /// Human label of the next scheduled day for a freshly created habit.
  static String? nextScheduledWeekdayLabel(int mask, {DateTime? now}) {
    final indexes = weekdayIndexes(mask);
    if (indexes.isEmpty) {
      return null;
    }
    final current = (now ?? DateTime.now()).weekday - 1;
    for (var step = 0; step < 7; step++) {
      final index = (current + step) % 7;
      if (indexes.contains(index)) {
        return weekdayLabels[index];
      }
    }
    return null;
  }
}
