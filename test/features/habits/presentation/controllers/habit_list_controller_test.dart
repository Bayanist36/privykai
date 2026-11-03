import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';

import '../../../../support/fake_habit_repository.dart';

Habit _habit({
  String id = 'habit-1',
  String name = 'Вода',
  int weekdaysMask = Habit.allWeekdaysMask,
  List<String> completedDates = const <String>[],
  DateTime? createdAt,
}) {
  return Habit(
    id: id,
    name: name,
    iconKey: 'water',
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    weekdaysMask: weekdaysMask,
    completedDates: completedDates,
  );
}

void main() {
  test('load exposes repository habits and clears loading state', () async {
    final repository = FakeHabitRepository([_habit()]);
    final controller = HabitListController(repository);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.habits, hasLength(1));
    expect(controller.totalCount, 1);
    expect(controller.hasHabits, isTrue);
  });

  test('addHabit trims the name and persists the habit', () async {
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository);
    await controller.load();

    final saved = await controller.addHabit(
      name: '  Чтение  ',
      iconKey: 'reading',
      reminderMinutes: 21 * 60,
    );

    expect(saved, isTrue);
    expect(controller.habits.single.name, 'Чтение');
    expect(controller.habits.single.reminderMinutes, 1260);
    expect(repository.habits, hasLength(1));
  });

  test('addHabit persists an interval reminder window', () async {
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository);
    await controller.load();

    final saved = await controller.addHabit(
      name: 'Вода',
      iconKey: 'water',
      reminderMinutes: 8 * 60,
      reminderIntervalHours: 2,
      reminderWindowEndMinutes: 22 * 60,
    );

    expect(saved, isTrue);
    final habit = controller.habits.single;
    expect(habit.isIntervalReminder, isTrue);
    expect(habit.reminderIntervalHours, 2);
    expect(habit.reminderWindowEndMinutes, 22 * 60);
    expect(habit.reminderTimesOfDay, hasLength(8));
    expect(repository.habits.single, habit);
  });

  test('addHabit persists the selected schedule and colour', () async {
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository);
    await controller.load();

    final saved = await controller.addHabit(
      name: 'Бег',
      iconKey: 'run',
      colorKey: 'blue',
      weekdaysMask: 0x15,
    );

    expect(saved, isTrue);
    expect(controller.habits.single.weekdaysMask, 0x15);
    expect(controller.habits.single.colorKey, 'blue');
    expect(controller.habits.single.isEveryDay, isFalse);
  });

  test('empty name is rejected', () async {
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository);
    await controller.load();

    final saved = await controller.addHabit(name: '   ', iconKey: 'water');

    expect(saved, isFalse);
    expect(controller.errorMessage, isNotNull);
    expect(repository.habits, isEmpty);
  });

  test('empty schedule is rejected', () async {
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository);
    await controller.load();

    final saved = await controller.addHabit(
      name: 'Бег',
      iconKey: 'run',
      weekdaysMask: 0,
    );

    expect(saved, isFalse);
    expect(controller.errorMessage, isNotNull);
    expect(repository.habits, isEmpty);
  });

  test('updateHabit keeps id, creation date and completion history', () async {
    final repository = FakeHabitRepository([
      _habit(completedDates: ['2026-10-20', '2026-10-21']),
    ]);
    final controller = HabitListController(repository);
    await controller.load();
    final original = controller.habits.single;

    final saved = await controller.updateHabit(
      habit: original,
      name: '  Пить 2 литра ',
      iconKey: 'water',
      colorKey: 'teal',
      weekdaysMask: 0x15,
      reminderMinutes: 9 * 60,
    );

    expect(saved, isTrue);
    final updated = controller.habits.single;
    expect(updated.id, original.id);
    expect(updated.createdAt, original.createdAt);
    expect(updated.completedDates, original.completedDates);
    expect(updated.name, 'Пить 2 литра');
    expect(updated.colorKey, 'teal');
    expect(updated.weekdaysMask, 0x15);
    expect(updated.reminderMinutes, 9 * 60);
    expect(repository.habits.single, updated);
  });

  test(
    'updateHabit can disable a reminder without losing other data',
    () async {
      final repository = FakeHabitRepository([
        _habit(completedDates: ['2026-10-20']),
      ]);
      final controller = HabitListController(repository);
      await controller.load();
      final original = controller.habits.single.copyWith(reminderMinutes: 480);

      await repository.save(original);
      await controller.load();

      final saved = await controller.updateHabit(
        habit: controller.habits.single,
        name: original.name,
        iconKey: original.iconKey,
        colorKey: original.colorKey,
        weekdaysMask: original.weekdaysMask,
        reminderMinutes: null,
      );

      expect(saved, isTrue);
      expect(controller.habits.single.hasReminder, isFalse);
      expect(controller.habits.single.completedDates, ['2026-10-20']);
    },
  );

  test('todayHabits only contains habits scheduled for today', () async {
    final todayMask = 1 << (DateTime.now().weekday - 1);
    final otherDay = DateTime.now().weekday == 7
        ? 1
        : DateTime.now().weekday + 1;
    final otherMask = 1 << (otherDay - 1);
    final todayKey = DateKey.from(DateTime.now());

    final repository = FakeHabitRepository([
      _habit(
        id: 'today',
        name: 'Сегодняшняя',
        weekdaysMask: todayMask,
        completedDates: [todayKey],
      ),
      _habit(
        id: 'other',
        name: 'Другая',
        weekdaysMask: otherMask,
        completedDates: [todayKey],
      ),
    ]);
    final controller = HabitListController(repository);
    await controller.load();

    expect(controller.todayHabits, hasLength(1));
    expect(controller.todayHabits.single.id, 'today');
    expect(controller.todayTotal, 1);
    expect(controller.unscheduledTodayCount, 1);
    expect(controller.completedToday, 1);
    expect(controller.totalCount, 2);
  });

  test('toggleCompletion updates today progress', () async {
    final repository = FakeHabitRepository([_habit()]);
    final controller = HabitListController(repository);
    await controller.load();

    await controller.toggleCompletion(controller.habits.single);

    expect(controller.completedToday, 1);
    expect(controller.todayProgress, 1);
    expect(repository.habits.single.isCompletedToday, isTrue);

    await controller.toggleCompletion(controller.habits.single);

    expect(controller.completedToday, 0);
  });

  test('deleteHabit removes and restoreHabit brings the habit back', () async {
    final repository = FakeHabitRepository([_habit()]);
    final controller = HabitListController(repository);
    await controller.load();
    final habit = controller.habits.single;

    await controller.deleteHabit(habit);
    expect(controller.habits, isEmpty);

    await controller.restoreHabit(habit);
    expect(controller.habits.single.id, habit.id);
  });

  test('clearAll removes every habit', () async {
    final repository = FakeHabitRepository([
      _habit(),
      _habit(id: 'habit-2', name: 'Чтение'),
    ]);
    final controller = HabitListController(repository);
    await controller.load();

    final cleared = await controller.clearAll();

    expect(cleared, isTrue);
    expect(controller.habits, isEmpty);
    expect(repository.habits, isEmpty);
  });

  test('write failure surfaces an error and keeps state', () async {
    final repository = FakeHabitRepository([_habit()]);
    final controller = HabitListController(repository);
    await controller.load();
    repository.failOnWrite = true;

    await controller.toggleCompletion(controller.habits.single);

    expect(controller.errorMessage, isNotNull);
    expect(controller.completedToday, 0);
  });
}
