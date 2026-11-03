import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/habits/data/models/habit_adapter.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';

void main() {
  test('reads a SUK-5 document with six fields and keeps completions', () {
    final habit = HabitAdapter.fromFields(<int, dynamic>{
      0: 'habit-1',
      1: 'Вода',
      2: 'water',
      3: 8 * 60,
      4: DateTime(2026, 1, 1),
      5: <String>['2026-10-21', '2026-10-22'],
    });

    expect(habit.id, 'habit-1');
    expect(habit.name, 'Вода');
    expect(habit.reminderMinutes, 480);
    expect(habit.completedDates, ['2026-10-21', '2026-10-22']);
    expect(habit.colorKey, Habit.defaultColorKey);
    expect(habit.weekdaysMask, Weekdays.everyDayMask);
  });

  test('reads new colour and schedule fields', () {
    final habit = HabitAdapter.fromFields(<int, dynamic>{
      0: 'habit-2',
      1: 'Бег',
      2: 'run',
      3: null,
      4: DateTime(2026, 1, 1),
      5: <String>[],
      6: 'blue',
      7: 0x15,
    });

    expect(habit.colorKey, 'blue');
    expect(habit.weekdaysMask, 0x15);
    expect(habit.isScheduledOn(DateTime(2026, 10, 19)), isTrue);
  });
}
