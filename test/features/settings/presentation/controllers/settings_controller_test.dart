import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';

import '../../../../support/fake_settings_repository.dart';

void main() {
  test('load exposes persisted settings', () async {
    final repository = FakeSettingsRepository(
      const AppSettings(
        themeMode: AppThemeMode.dark,
        remindersEnabled: false,
        defaultReminderMinutes: 9 * 60,
        onboardingCompleted: true,
      ),
    );
    final controller = SettingsController(repository);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.settings.themeMode, AppThemeMode.dark);
    expect(controller.settings.remindersEnabled, isFalse);
    expect(controller.settings.defaultReminderMinutes, 540);
    expect(controller.settings.onboardingCompleted, isTrue);
  });

  test('theme and reminder changes are saved immediately', () async {
    final repository = FakeSettingsRepository();
    final controller = SettingsController(repository);
    await controller.load();

    await controller.setThemeMode(AppThemeMode.light);
    await controller.setRemindersEnabled(false);
    await controller.setDefaultReminderMinutes(7 * 60);

    expect(repository.settings.themeMode, AppThemeMode.light);
    expect(repository.settings.remindersEnabled, isFalse);
    expect(repository.settings.defaultReminderMinutes, 420);
    expect(repository.saveCalls, 3);
  });

  test('completing onboarding persists the flag', () async {
    final repository = FakeSettingsRepository(const AppSettings());
    final controller = SettingsController(repository);
    await controller.load();

    await controller.completeOnboarding();

    expect(controller.settings.onboardingCompleted, isTrue);
    expect(repository.settings.onboardingCompleted, isTrue);
  });

  test(
    'resetPreferences restores defaults but keeps onboarding done',
    () async {
      final repository = FakeSettingsRepository(
        const AppSettings(
          themeMode: AppThemeMode.dark,
          remindersEnabled: false,
          defaultReminderMinutes: 9 * 60,
          onboardingCompleted: true,
        ),
      );
      final controller = SettingsController(repository);
      await controller.load();

      await controller.resetPreferences();

      expect(controller.settings.themeMode, AppThemeMode.system);
      expect(controller.settings.remindersEnabled, isTrue);
      expect(controller.settings.defaultReminderMinutes, 8 * 60);
      expect(controller.settings.onboardingCompleted, isTrue);
    },
  );

  test('failed write rolls the setting back and reports an error', () async {
    final repository = FakeSettingsRepository();
    final controller = SettingsController(repository);
    await controller.load();
    repository.failOnWrite = true;

    await controller.setThemeMode(AppThemeMode.dark);

    expect(controller.settings.themeMode, AppThemeMode.system);
    expect(controller.errorMessage, isNotNull);
  });
}
