import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_info.dart';
import 'package:habit_tracker/app/app_shell.dart';
import 'package:habit_tracker/app/theme/app_theme.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/onboarding/presentation/onboarding_screen.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';
import 'package:habit_tracker/features/widget/domain/home_widget_bridge.dart';

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({
    required this.repository,
    required this.settingsRepository,
    this.reminderScheduler,
    this.homeWidget,
    super.key,
  });

  final HabitRepository repository;
  final SettingsRepository settingsRepository;
  final ReminderScheduler? reminderScheduler;
  final HomeWidgetBridge? homeWidget;

  @override
  Widget build(BuildContext context) {
    final scheduler = reminderScheduler ?? const NoopReminderScheduler();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitListController>(
          create: (_) => HabitListController(
            repository,
            reminders: scheduler,
            homeWidget: homeWidget,
          )..load(),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(settingsRepository)..load(),
        ),
        Provider<ReminderScheduler>.value(value: scheduler),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppInfo.name,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _AppRoot(),
          );
        },
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final habits = context.watch<HabitListController>();

    if (settings.isLoading || habits.isLoading) {
      return const _SplashScreen();
    }

    // A pre-existing installation never sees the first-run slides, even if the
    // settings document was created before the flag existed.
    final needsOnboarding =
        !settings.settings.onboardingCompleted && habits.habits.isEmpty;

    return needsOnboarding ? const OnboardingScreen() : const AppShell();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
