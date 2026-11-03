import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:habit_tracker/features/habits/data/datasources/habit_local_data_source.dart';
import 'package:habit_tracker/features/habits/data/models/habit_adapter.dart';
import 'package:habit_tracker/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/settings/data/models/app_settings_adapter.dart';
import 'package:habit_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:habit_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/statistics/domain/habit_statistics.dart';

import '../../../support/fake_reminder_scheduler.dart';

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('habit_hive_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(HabitAdapter.habitTypeId)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(AppSettingsAdapter.settingsTypeId)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('statistics are computed from habits persisted in Hive', () async {
    final box = await Hive.openBox<Habit>('habits');
    final repository = HabitRepositoryImpl(HabitLocalDataSource(box));
    await repository.save(
      Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: DateTime(2026, 10, 1),
        reminderMinutes: 8 * 60,
        weekdaysMask: 0x15,
        completedDates: ['2026-10-19', '2026-10-21'],
      ),
    );

    final reminders = FakeReminderScheduler();
    final controller = HabitListController(repository, reminders: reminders);
    await controller.load();

    final summary = HabitStatistics.summary(
      controller.habits,
      today: DateTime(2026, 10, 23),
    );

    expect(controller.habits.single.reminderMinutes, 8 * 60);
    expect(controller.habits.single.weekdaysMask, 0x15);
    expect(summary.completed, 2);
    expect(summary.planned, 3);
    expect(summary.percent, 67);
    expect(reminders.syncCalls.single.habits.single.id, 'habit-1');
  });

  test(
    'habit survives close and a second openBox (BUG-01 regression)',
    () async {
      final first = await Hive.openBox<Habit>('habits');
      await HabitRepositoryImpl(HabitLocalDataSource(first)).save(
        Habit(
          id: 'habit-reopen',
          name: 'Читать 20 минут',
          iconKey: 'reading',
          colorKey: 'blue',
          createdAt: DateTime(2026, 10, 20),
          reminderMinutes: 21 * 60,
          weekdaysMask: 0x15,
          completedDates: ['2026-10-21', '2026-10-22'],
        ),
      );
      await first.close();

      final reopened = await Hive.openBox<Habit>('habits');
      final habits = await HabitRepositoryImpl(HabitLocalDataSource(reopened))
          .getAll();

      expect(habits, hasLength(1));
      expect(habits.single.id, 'habit-reopen');
      expect(habits.single.name, 'Читать 20 минут');
      expect(habits.single.colorKey, 'blue');
      expect(habits.single.reminderMinutes, 21 * 60);
      expect(habits.single.weekdaysMask, 0x15);
      expect(habits.single.completedDates, ['2026-10-21', '2026-10-22']);
    },
  );

  test(
    'settings survive close and a second openBox (BUG-04 regression)',
    () async {
      final first = await Hive.openBox<AppSettings>('settings');
      const saved = AppSettings(
        themeMode: AppThemeMode.dark,
        remindersEnabled: false,
        defaultReminderMinutes: 7 * 60 + 30,
        onboardingCompleted: true,
      );
      await SettingsRepositoryImpl(SettingsLocalDataSource(first)).save(saved);
      await first.close();

      final reopened = await Hive.openBox<AppSettings>('settings');
      final loaded = await SettingsRepositoryImpl(
        SettingsLocalDataSource(reopened),
      ).load();

      expect(loaded, saved);
      expect(loaded.themeMode, AppThemeMode.dark);
      expect(loaded.onboardingCompleted, isTrue);
    },
  );
}
