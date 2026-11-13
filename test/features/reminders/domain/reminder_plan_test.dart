import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';

void main() {
  group('ReminderPlan.weekdayIndexes', () {
    test('maps Monday to 0 and Sunday to 6', () {
      expect(ReminderPlan.weekdayIndexes(0x7F), [0, 1, 2, 3, 4, 5, 6]);
      expect(ReminderPlan.weekdayIndexes(0x15), [0, 2, 4]);
      expect(ReminderPlan.weekdayIndexes(1 << 6), [6]);
    });
  });

  group('ReminderPlan.weekdaysLabel', () {
    test('describes every-day and custom schedules', () {
      expect(ReminderPlan.weekdaysLabel(0x7F), 'Каждый день');
      expect(ReminderPlan.weekdaysLabel(0x15), 'Пн, Ср, Пт');
      expect(ReminderPlan.weekdaysLabel(0), 'Выберите хотя бы один день');
    });
  });

  group('ReminderPlan.notificationId', () {
    test('is stable for the same habit and weekday', () {
      final first = ReminderPlan.notificationId('habit-1', 2);
      final second = ReminderPlan.notificationId('habit-1', 2);

      expect(first, second);
      expect(first, greaterThan(0));
    });

    test('differs per habit and per weekday', () {
      expect(
        ReminderPlan.notificationId('habit-1', 2),
        isNot(ReminderPlan.notificationId('habit-1', 3)),
      );
      expect(
        ReminderPlan.notificationId('habit-1', 2),
        isNot(ReminderPlan.notificationId('habit-2', 2)),
      );
    });

    test('differs per interval slot', () {
      expect(
        ReminderPlan.notificationId('habit-1', 2, slotIndex: 0),
        isNot(ReminderPlan.notificationId('habit-1', 2, slotIndex: 1)),
      );
    });
  });

  group('ReminderPlan.nextOccurrence', () {
    final fridayMorning = DateTime(2026, 10, 23, 7, 30); // Friday

    test('schedules a later time today', () {
      final next = ReminderPlan.nextOccurrence(
        now: fridayMorning,
        weekdayIndex: 4, // Friday
        minutesSinceMidnight: 8 * 60,
      );

      expect(next, DateTime(2026, 10, 23, 8));
    });

    test('moves to the next week when the time has passed', () {
      final next = ReminderPlan.nextOccurrence(
        now: DateTime(2026, 10, 23, 9),
        weekdayIndex: 4,
        minutesSinceMidnight: 8 * 60,
      );

      expect(next, DateTime(2026, 10, 30, 8));
    });

    test('rolls over to the next scheduled weekday', () {
      final next = ReminderPlan.nextOccurrence(
        now: fridayMorning,
        weekdayIndex: 0, // Monday
        minutesSinceMidnight: 8 * 60,
      );

      expect(next, DateTime(2026, 10, 26, 8));
    });
  });

  group('ReminderPlan.planFor', () {
    Habit habit({
      int weekdaysMask = 0x7F,
      int? reminderMinutes = 8 * 60,
      int? reminderIntervalHours,
      int reminderWindowEndMinutes = 22 * 60,
    }) {
      return Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        weekdaysMask: weekdaysMask,
        reminderMinutes: reminderMinutes,
        reminderIntervalHours: reminderIntervalHours,
        reminderWindowEndMinutes: reminderWindowEndMinutes,
      );
    }

    test('creates one reminder per selected weekday', () {
      final plan = ReminderPlan.planFor(
        habit(weekdaysMask: 0x15),
        now: DateTime(2026, 10, 23, 7, 30),
      );

      expect(plan, hasLength(3));
      expect(plan.map((reminder) => reminder.weekdayIndex), [0, 2, 4]);
      expect(plan.first.dateTime, DateTime(2026, 10, 26, 8));
      expect(plan.last.dateTime, DateTime(2026, 10, 23, 8));
    });

    test('uses stable notification ids from the plan', () {
      final plan = ReminderPlan.planFor(
        habit(),
        now: DateTime(2026, 10, 23, 7, 30),
      );

      expect(plan, hasLength(7));
      expect(plan.first.id, ReminderPlan.notificationId('habit-1', 0));
      expect(plan.last.id, ReminderPlan.notificationId('habit-1', 6));
    });

    test('returns nothing without a reminder time', () {
      final plan = ReminderPlan.planFor(
        habit(reminderMinutes: null),
        now: DateTime(2026, 10, 23, 7, 30),
      );

      expect(plan, isEmpty);
    });

    test('creates one reminder per weekday and per interval slot', () {
      final plan = ReminderPlan.planFor(
        habit(weekdaysMask: 1 << 0, reminderIntervalHours: 2),
        now: DateTime(2026, 10, 23, 7, 30),
      );

      expect(plan, hasLength(8));
      expect(plan.map((reminder) => reminder.weekdayIndex), everyElement(0));
      expect(plan.map((reminder) => reminder.slotIndex), [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
      expect(plan.map((reminder) => reminder.dateTime.hour), [
        8,
        10,
        12,
        14,
        16,
        18,
        20,
        22,
      ]);
      expect(plan.first.dateTime, DateTime(2026, 10, 26, 8));
      expect(plan.last.dateTime, DateTime(2026, 10, 26, 22));
      expect(plan.map((reminder) => reminder.id).toSet(), hasLength(8));
    });
  });

  group('ReminderPlan.eveningPlan', () {
    test('creates one evening reminder per weekday', () {
      final plan = ReminderPlan.eveningPlan(
        evening: const EveningReminder(minutes: 20 * 60),
        now: DateTime(2026, 10, 23, 19),
      );

      expect(plan, hasLength(7));
      expect(plan.map((reminder) => reminder.weekdayIndex), [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      expect(plan.map((reminder) => reminder.id).toSet(), hasLength(7));
      expect(plan.first.dateTime, DateTime(2026, 10, 26, 20));
      expect(plan.last.dateTime, DateTime(2026, 10, 25, 20));
    });

    test('returns nothing when the evening reminder is off', () {
      expect(
        ReminderPlan.eveningPlan(
          evening: null,
          now: DateTime(2026, 10, 23, 19),
        ),
        isEmpty,
      );
    });
  });

  test('nextScheduledWeekdayLabel names the first scheduled day', () {
    expect(
      ReminderPlan.nextScheduledWeekdayLabel(
        1 << 0,
        now: DateTime(2026, 10, 23),
      ),
      'понедельник',
    );
  });

  group('ReminderPlan.eveningPlan with skipToday', () {
    test('makes today’s occurrence a one-shot next week', () {
      final plan = ReminderPlan.eveningPlan(
        evening: const EveningReminder(minutes: 20 * 60, skipToday: true),
        now: DateTime(2026, 10, 23, 19), // Friday
      );

      final friday = plan.firstWhere((reminder) => reminder.weekdayIndex == 4);
      final monday = plan.firstWhere((reminder) => reminder.weekdayIndex == 0);

      expect(friday.dateTime, DateTime(2026, 10, 30, 20));
      expect(friday.repeatsWeekly, isFalse);
      expect(monday.dateTime, DateTime(2026, 10, 26, 20));
      expect(monday.repeatsWeekly, isTrue);
      expect(plan.where((reminder) => reminder.repeatsWeekly), hasLength(6));
    });

    test('keeps the weekly repeat when today’s time has already passed', () {
      final plan = ReminderPlan.eveningPlan(
        evening: const EveningReminder(minutes: 20 * 60, skipToday: true),
        now: DateTime(2026, 10, 23, 21), // Friday, later than 20:00
      );

      final friday = plan.firstWhere((reminder) => reminder.weekdayIndex == 4);
      expect(friday.dateTime, DateTime(2026, 10, 30, 20));
      expect(friday.repeatsWeekly, isTrue);
    });

    test('keeps every weekday weekly when today is not skipped', () {
      final plan = ReminderPlan.eveningPlan(
        evening: const EveningReminder(minutes: 20 * 60),
        now: DateTime(2026, 10, 23, 19), // Friday
      );

      expect(plan.every((reminder) => reminder.repeatsWeekly), isTrue);
      final friday = plan.firstWhere((reminder) => reminder.weekdayIndex == 4);
      expect(friday.dateTime, DateTime(2026, 10, 23, 20));
    });
  });

  group('ReminderPlan.effectiveEvening', () {
    Habit habit({List<String> completedDates = const <String>[]}) {
      return Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        weekdaysMask: 0x7F,
        reminderMinutes: 8 * 60,
        completedDates: completedDates,
      );
    }

    test('suppresses the nudge when every habit is completed', () {
      final evening = ReminderPlan.effectiveEvening(
        evening: const EveningReminder(minutes: 20 * 60),
        habits: <Habit>[
          habit(completedDates: const <String>['2026-10-23']),
        ],
        now: DateTime(2026, 10, 23, 19),
      );

      expect(evening?.skipToday, isTrue);
    });

    test('keeps the nudge when a habit is still open', () {
      final evening = ReminderPlan.effectiveEvening(
        evening: const EveningReminder(minutes: 20 * 60),
        habits: <Habit>[habit()],
        now: DateTime(2026, 10, 23, 19),
      );

      expect(evening?.skipToday, isFalse);
    });

    test('suppresses the nudge when there are no habits', () {
      final evening = ReminderPlan.effectiveEvening(
        evening: const EveningReminder(minutes: 20 * 60),
        habits: const <Habit>[],
        now: DateTime(2026, 10, 23, 19),
      );

      expect(evening?.skipToday, isTrue);
    });
  });

  group('ReminderPlan.capToLimit', () {
    test('keeps the nearest reminders and drops the distant tail', () {
      final plan = <PlannedReminder>[
        for (var hour = 10; hour < 15; hour++)
          PlannedReminder(
            id: hour,
            weekdayIndex: 0,
            dateTime: DateTime(2026, 10, 26, hour),
          ),
      ];

      final capped = ReminderPlan.capToLimit(plan, limit: 3);

      expect(capped, hasLength(3));
      expect(capped.map((reminder) => reminder.dateTime.hour), <int>[
        10,
        11,
        12,
      ]);
    });

    test('returns the whole plan when it fits', () {
      final plan = <PlannedReminder>[
        PlannedReminder(
          id: 1,
          weekdayIndex: 0,
          dateTime: DateTime(2026, 10, 26, 10),
        ),
      ];

      expect(ReminderPlan.capToLimit(plan, limit: 400), hasLength(1));
    });
  });
}
