import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/utils/russian_plural.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';

Habit _habit({
  List<String> completedDates = const <String>[],
  int weekdaysMask = Habit.allWeekdaysMask,
  DateTime? createdAt,
}) {
  return Habit(
    id: 'habit-1',
    name: 'Вода',
    iconKey: 'water',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    weekdaysMask: weekdaysMask,
    completedDates: completedDates,
  );
}

void main() {
  group('Habit.toggleCompletion', () {
    test('adds a completion for the given day', () {
      final habit = _habit().toggleCompletion(DateTime(2026, 10, 23));

      expect(habit.completedDates, ['2026-10-23']);
      expect(habit.isCompletedOn(DateTime(2026, 10, 23)), isTrue);
    });

    test('removes an existing completion and keeps dates sorted', () {
      final habit = _habit(completedDates: ['2026-10-21', '2026-10-23'])
          .toggleCompletion(DateTime(2026, 10, 21));

      expect(habit.completedDates, ['2026-10-23']);
    });
  });

  group('Habit schedule', () {
    // 2026-10-19 is Monday; 0x15 = Monday, Wednesday, Friday.
    const monWedFri = 0x15;

    test('recognises scheduled and unscheduled weekdays', () {
      final habit = _habit(weekdaysMask: monWedFri);

      expect(habit.isScheduledOn(DateTime(2026, 10, 19)), isTrue);
      expect(habit.isScheduledOn(DateTime(2026, 10, 20)), isFalse);
      expect(habit.isScheduledOn(DateTime(2026, 10, 23)), isTrue);
    });

    test('does not schedule days before the creation date', () {
      final habit = _habit(createdAt: DateTime(2026, 10, 21));

      expect(habit.isScheduledOn(DateTime(2026, 10, 20)), isFalse);
      expect(habit.isScheduledOn(DateTime(2026, 10, 21)), isTrue);
    });

    test('skips unscheduled days without breaking the streak', () {
      final habit = _habit(
        weekdaysMask: monWedFri,
        completedDates: ['2026-10-19', '2026-10-21'],
      );

      expect(habit.currentStreak(today: DateTime(2026, 10, 22)), 2);
    });

    test('keeps the streak while today is still open', () {
      final habit = _habit(
        weekdaysMask: monWedFri,
        completedDates: ['2026-10-19', '2026-10-21'],
      );

      expect(habit.currentStreak(today: DateTime(2026, 10, 23)), 2);
    });

    test('counts a completed scheduled day as one', () {
      final habit = _habit(
        weekdaysMask: monWedFri,
        completedDates: ['2026-10-23'],
      );

      expect(habit.currentStreak(today: DateTime(2026, 10, 23)), 1);
    });

    test('bestStreak returns the longest scheduled run', () {
      final habit = _habit(
        weekdaysMask: monWedFri,
        completedDates: [
          '2026-10-12',
          '2026-10-14',
          '2026-10-16',
          '2026-10-19',
          '2026-10-21',
        ],
      );

      expect(habit.bestStreak(today: DateTime(2026, 10, 23)), 5);
    });
  });

  group('Habit.currentStreak', () {
    test('counts consecutive days ending today', () {
      final habit = _habit(
        completedDates: ['2026-10-21', '2026-10-22', '2026-10-23'],
      );

      expect(habit.currentStreak(today: DateTime(2026, 10, 23)), 3);
    });

    test('keeps yesterday streak while today is not completed yet', () {
      final habit = _habit(completedDates: ['2026-10-21', '2026-10-22']);

      expect(habit.currentStreak(today: DateTime(2026, 10, 23)), 2);
    });

    test('returns zero when the last completion is older than yesterday', () {
      final habit = _habit(completedDates: ['2026-10-20']);

      expect(habit.currentStreak(today: DateTime(2026, 10, 23)), 0);
    });
  });

  group('Habit.reminderTimesOfDay', () {
    Habit withReminder({
      int? reminderMinutes = 8 * 60,
      int? intervalHours,
      int windowEndMinutes = 22 * 60,
    }) {
      return Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        reminderMinutes: reminderMinutes,
        reminderIntervalHours: intervalHours,
        reminderWindowEndMinutes: windowEndMinutes,
      );
    }

    test('returns one time for a single daily reminder', () {
      final habit = withReminder();

      expect(habit.isIntervalReminder, isFalse);
      expect(habit.reminderTimesOfDay, [8 * 60]);
    });

    test('steps through the window every N hours', () {
      final habit = withReminder(intervalHours: 2);

      expect(habit.isIntervalReminder, isTrue);
      expect(habit.reminderTimesOfDay, [
        8 * 60,
        10 * 60,
        12 * 60,
        14 * 60,
        16 * 60,
        18 * 60,
        20 * 60,
        22 * 60,
      ]);
    });

    test(
      'keeps only the start when the window is shorter than the interval',
      () {
        final habit = withReminder(
          intervalHours: 3,
          windowEndMinutes: 9 * 60 + 30,
        );

        expect(habit.reminderTimesOfDay, [8 * 60]);
      },
    );

    test('keeps only the start when the window ends at the start', () {
      final habit = withReminder(intervalHours: 1, windowEndMinutes: 8 * 60);

      expect(habit.reminderTimesOfDay, [8 * 60]);
    });

    test('caps the number of slots per day', () {
      final habit = withReminder(
        reminderMinutes: 0,
        intervalHours: 1,
        windowEndMinutes: 23 * 60 + 59,
      );

      expect(habit.reminderTimesOfDay, hasLength(Habit.maxRemindersPerDay));
    });

    test('returns nothing without a reminder time', () {
      final habit = withReminder(reminderMinutes: null, intervalHours: 2);

      expect(habit.hasReminder, isFalse);
      expect(habit.isIntervalReminder, isFalse);
      expect(habit.reminderTimesOfDay, isEmpty);
    });
  });

  test('RussianPlural.streak handles Russian plural forms', () {
    expect(RussianPlural.streak(1), '1 день подряд');
    expect(RussianPlural.streak(3), '3 дня подряд');
    expect(RussianPlural.streak(5), '5 дней подряд');
    expect(RussianPlural.streak(11), '11 дней подряд');
    expect(RussianPlural.streak(0), 'Серия начнётся сегодня');
  });
}
