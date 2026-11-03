import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/statistics/domain/habit_statistics.dart';

Habit _habit({
  String id = 'habit-1',
  int weekdaysMask = Habit.allWeekdaysMask,
  DateTime? createdAt,
  List<String> completedDates = const <String>[],
}) {
  return Habit(
    id: id,
    name: 'Вода',
    iconKey: 'water',
    createdAt: createdAt ?? DateTime(2026, 10, 1),
    weekdaysMask: weekdaysMask,
    completedDates: completedDates,
  );
}

void main() {
  final today = DateTime(2026, 10, 23); // Friday

  group('HabitStatistics.summary', () {
    test('counts completed and planned scheduled slots for 7 days', () {
      final habit = _habit(
        completedDates: [
          '2026-10-17',
          '2026-10-19',
          '2026-10-20',
          '2026-10-21',
          '2026-10-22',
        ],
      );

      final summary = HabitStatistics.summary([habit], today: today);

      expect(summary.completed, 5);
      expect(summary.planned, 7);
      expect(summary.percent, 71);
    });

    test('includes today unfinished scheduled slot', () {
      final habit = _habit(
        completedDates: [
          '2026-10-17',
          '2026-10-18',
          '2026-10-19',
          '2026-10-20',
          '2026-10-21',
          '2026-10-22',
        ],
      );

      final summary = HabitStatistics.summary([habit], today: today);

      expect(summary.completed, 6);
      expect(summary.planned, 7);
      expect(summary.percent, 86);
    });

    test('only counts days from the weekday schedule', () {
      // Mon/Wed/Fri: 19, 21, 23 fall into the 7-day window.
      final habit = _habit(
        weekdaysMask: 0x15,
        completedDates: ['2026-10-19', '2026-10-21'],
      );

      final summary = HabitStatistics.summary([habit], today: today);

      expect(summary.completed, 2);
      expect(summary.planned, 3);
      expect(summary.percent, 67);
    });

    test('aggregates several habits by slots, not by percent average', () {
      final first = _habit(
        id: 'a',
        completedDates: ['2026-10-23'],
      );
      final second = _habit(
        id: 'b',
        weekdaysMask: 1 << 3, // Thursday only
        completedDates: ['2026-10-22'],
      );

      final summary = HabitStatistics.summary([first, second], today: today);

      expect(summary.completed, 2);
      expect(summary.planned, 8);
      expect(summary.percent, 25);
    });

    test('returns zero for an empty list', () {
      final summary = HabitStatistics.summary(const [], today: today);

      expect(summary.completed, 0);
      expect(summary.planned, 0);
      expect(summary.percent, 0);
      expect(summary.ratio, 0);
    });
  });

  group('HabitStatistics.periodSummary', () {
    test('does not schedule slots before the creation date', () {
      final habit = _habit(
        createdAt: DateTime(2026, 10, 22),
        completedDates: ['2026-10-22'],
      );

      final summary = HabitStatistics.periodSummary(
        habit,
        today: today,
        days: 30,
      );

      expect(summary.completed, 1);
      expect(summary.planned, 2);
      expect(summary.percent, 50);
    });

    test('a habit created today has one planned slot', () {
      final habit = _habit(createdAt: today);

      final summary = HabitStatistics.periodSummary(
        habit,
        today: today,
        days: 30,
      );

      expect(summary.completed, 0);
      expect(summary.planned, 1);
    });
  });

  group('HabitStatistics.habitStats', () {
    test('returns 30-day percent and both streaks', () {
      final habit = _habit(
        weekdaysMask: 0x15,
        completedDates: [
          '2026-10-12',
          '2026-10-14',
          '2026-10-16',
          '2026-10-19',
          '2026-10-21',
        ],
      );

      final stats = HabitStatistics.habitStats(habit, today: today);

      expect(stats.currentStreak, 5);
      expect(stats.bestStreak, 5);
      // Days before createdAt are excluded: 10 scheduled weekdays from
      // 1 Oct to 23 Oct, 5 of them completed.
      expect(stats.percent, 50);
    });
  });

  test('hasAnyCompletion detects at least one completion', () {
    expect(
      HabitStatistics.hasAnyCompletion([_habit(), _habit(id: 'b')]),
      isFalse,
    );
    expect(
      HabitStatistics.hasAnyCompletion([
        _habit(completedDates: ['2026-10-23']),
      ]),
      isTrue,
    );
  });
}
