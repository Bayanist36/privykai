import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:habit_tracker/app/app.dart';
import 'package:habit_tracker/core/storage/hive_storage.dart';
import 'package:habit_tracker/features/habits/data/datasources/habit_local_data_source.dart';
import 'package:habit_tracker/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:habit_tracker/features/reminders/data/flutter_local_reminder_scheduler.dart';
import 'package:habit_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:habit_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/widget/data/home_widget_bridge_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await HiveStorage.init();

  final habitRepository = HabitRepositoryImpl(
    HabitLocalDataSource(HiveStorage.habitsBox),
  );

  // Users upgrading from the SUK-5 build already have habits: skip the
  // first-run slides for them instead of showing them on update.
  final settingsRepository = SettingsRepositoryImpl(
    SettingsLocalDataSource(
      HiveStorage.settingsBox,
      fallback: AppSettings.defaults.copyWith(
        onboardingCompleted: HiveStorage.habitsBox.isNotEmpty,
      ),
    ),
  );

  final reminderScheduler = FlutterLocalReminderScheduler();
  try {
    await reminderScheduler.initialize();
  } catch (error) {
    debugPrint('Reminder scheduler initialization failed: $error');
  }

  runApp(
    HabitTrackerApp(
      repository: habitRepository,
      settingsRepository: settingsRepository,
      reminderScheduler: reminderScheduler,
      homeWidget: const HomeWidgetBridgeImpl(),
    ),
  );
}
