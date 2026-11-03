import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';

/// Completed and planned scheduled slots inside a date window.
class PeriodSummary {
  const PeriodSummary({required this.completed, required this.planned});

  static const PeriodSummary empty = PeriodSummary(completed: 0, planned: 0);

  final int completed;
  final int planned;

  double get ratio => planned == 0 ? 0 : completed / planned;

  int get percent => (ratio * 100).round();
}

/// Per-habit numbers rendered on the statistics screen.
class HabitPeriodStats {
  const HabitPeriodStats({
    required this.percent,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int percent;
  final int currentStreak;
  final int bestStreak;
}

/// Pure statistics over the persisted completion dates.
///
/// Every calculation only counts scheduled days (weekday mask) and ignores
/// days before the habit was created. Today's unfinished scheduled slot is
/// included in the denominator.
abstract final class HabitStatistics {
  static const int summaryDays = 7;
  static const int habitDays = 30;

  static PeriodSummary summary(
    Iterable<Habit> habits, {
    DateTime? today,
    int days = summaryDays,
  }) {
    final day = Habit.dateOnly(today ?? DateTime.now());
    var completed = 0;
    var planned = 0;
    for (final habit in habits) {
      final period = periodSummary(habit, today: day, days: days);
      completed += period.completed;
      planned += period.planned;
    }
    return PeriodSummary(completed: completed, planned: planned);
  }

  static PeriodSummary periodSummary(
    Habit habit, {
    DateTime? today,
    int days = habitDays,
  }) {
    final end = Habit.dateOnly(today ?? DateTime.now());
    final start = DateTime(end.year, end.month, end.day - (days - 1));
    final completedDates = habit.completedDates.toSet();

    var completed = 0;
    var planned = 0;
    var cursor = start;
    while (!cursor.isAfter(end)) {
      if (habit.isScheduledOn(cursor)) {
        planned++;
        if (completedDates.contains(DateKey.from(cursor))) {
          completed++;
        }
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    return PeriodSummary(completed: completed, planned: planned);
  }

  static HabitPeriodStats habitStats(Habit habit, {DateTime? today}) {
    final day = Habit.dateOnly(today ?? DateTime.now());
    final period = periodSummary(habit, today: day, days: habitDays);
    return HabitPeriodStats(
      percent: period.percent,
      currentStreak: habit.currentStreak(today: day),
      bestStreak: habit.bestStreak(today: day),
    );
  }

  static bool hasAnyCompletion(Iterable<Habit> habits) =>
      habits.any((habit) => habit.completedDates.isNotEmpty);
}
