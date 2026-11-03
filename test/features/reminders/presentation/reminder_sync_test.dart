import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';

import '../../../support/fake_habit_repository.dart';
import '../../../support/fake_reminder_scheduler.dart';

Habit _habit({String id = 'habit-1', int? reminderMinutes = 8 * 60}) {
  return Habit(
    id: id,
    name: 'Вода',
    iconKey: 'water',
    createdAt: DateTime(2026, 1, 1),
    reminderMinutes: reminderMinutes,
    weekdaysMask: 0x15,
  );
}

void main() {
  test('load schedules the loaded habits', () async {
    final reminders = FakeReminderScheduler();
    final controller = HabitListController(
      FakeHabitRepository([_habit()]),
      reminders: reminders,
    );

    await controller.load();

    expect(reminders.syncCalls, hasLength(1));
    expect(reminders.syncCalls.single.habits.single.id, 'habit-1');
    expect(reminders.syncCalls.single.enabled, isTrue);
  });

  test('add, update and delete re-schedule notifications', () async {
    final reminders = FakeReminderScheduler();
    final repository = FakeHabitRepository();
    final controller = HabitListController(repository, reminders: reminders);
    await controller.load();
    reminders.syncCalls.clear();

    await controller.addHabit(
      name: 'Вода',
      iconKey: 'water',
      reminderMinutes: 8 * 60,
      weekdaysMask: 0x15,
    );
    expect(reminders.syncCalls, hasLength(1));

    final habit = controller.habits.single;
    await controller.updateHabit(
      habit: habit,
      name: 'Вода 2 литра',
      iconKey: 'water',
      colorKey: habit.colorKey,
      weekdaysMask: 0x1F,
      reminderMinutes: 9 * 60,
    );
    expect(reminders.syncCalls, hasLength(2));
    expect(reminders.syncCalls.last.habits.single.weekdaysMask, 0x1F);

    await controller.deleteHabit(controller.habits.single);
    expect(reminders.syncCalls, hasLength(3));
    expect(reminders.syncCalls.last.habits, isEmpty);
  });

  test('global switch disables scheduling without clearing habits', () async {
    final reminders = FakeReminderScheduler();
    final controller = HabitListController(
      FakeHabitRepository([_habit()]),
      reminders: reminders,
    );
    await controller.load();
    reminders.syncCalls.clear();

    await controller.syncReminders(enabled: false);

    expect(reminders.syncCalls.single.enabled, isFalse);
    expect(controller.habits, hasLength(1));
  });

  test('setEveningReminder forwards the time and clears it when off', () async {
    final reminders = FakeReminderScheduler();
    final controller = HabitListController(
      FakeHabitRepository([_habit()]),
      reminders: reminders,
    );
    await controller.load();
    reminders.syncCalls.clear();

    await controller.setEveningReminder(
      const EveningReminder(minutes: 20 * 60),
    );
    expect(reminders.syncCalls, hasLength(1));
    expect(
      reminders.syncCalls.single.evening,
      const EveningReminder(minutes: 20 * 60),
    );

    await controller.setEveningReminder(null);
    expect(reminders.syncCalls, hasLength(2));
    expect(reminders.syncCalls.last.evening, isNull);
  });

  test('clearAll cancels reminders', () async {
    final reminders = FakeReminderScheduler();
    final controller = HabitListController(
      FakeHabitRepository([_habit()]),
      reminders: reminders,
    );
    await controller.load();
    reminders.syncCalls.clear();

    await controller.clearAll();

    expect(reminders.syncCalls.single.habits, isEmpty);
  });

  test('scheduler failure does not fail habit mutations', () async {
    final reminders = _ThrowingReminderScheduler();
    final controller = HabitListController(
      FakeHabitRepository(),
      reminders: reminders,
    );
    await controller.load();

    final saved = await controller.addHabit(name: 'Вода', iconKey: 'water');

    expect(saved, isTrue);
    expect(controller.errorMessage, isNull);
    expect(controller.habits, hasLength(1));
  });
}

class _ThrowingReminderScheduler extends FakeReminderScheduler {
  @override
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  }) async {
    throw StateError('scheduler failed');
  }
}
