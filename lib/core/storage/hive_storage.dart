import 'package:hive_flutter/hive_flutter.dart';

import 'package:habit_tracker/features/habits/data/models/habit_adapter.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/settings/data/models/app_settings_adapter.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// Opens the local database once during startup.
///
/// The app is offline-first: Hive is the only source of truth and no network
/// permissions or backend are involved.
abstract final class HiveStorage {
  static const String habitsBoxName = 'habits';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(HabitAdapter().typeId)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(AppSettingsAdapter().typeId)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    await Hive.openBox<Habit>(habitsBoxName);
    await Hive.openBox<AppSettings>(settingsBoxName);
  }

  static Box<Habit> get habitsBox => Hive.box<Habit>(habitsBoxName);

  static Box<AppSettings> get settingsBox =>
      Hive.box<AppSettings>(settingsBoxName);

  static Future<void> close() => Hive.close();
}
