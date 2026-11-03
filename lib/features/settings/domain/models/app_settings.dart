import 'package:flutter/foundation.dart';

/// Three theme modes from the product brief (US-10).
enum AppThemeMode {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.storageValue);

  final String storageValue;

  static AppThemeMode fromStorage(Object? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => AppThemeMode.system,
    );
  }
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.remindersEnabled = true,
    this.defaultReminderMinutes = 8 * 60,
    this.onboardingCompleted = false,
    this.eveningReminderEnabled = false,
    this.eveningReminderMinutes = defaultEveningMinutes,
  });

  static const AppSettings defaults = AppSettings();

  /// 20:00 — a reasonable "before the day ends" nudge.
  static const int defaultEveningMinutes = 20 * 60;

  final AppThemeMode themeMode;

  /// Global reminder switch. Persisted now; scheduling arrives with SUK-9.
  final bool remindersEnabled;

  /// Minutes since midnight, used for new habits (design default 08:00).
  final int defaultReminderMinutes;

  /// First-run onboarding completion flag. Existing installations are migrated
  /// to `true`, so the update does not surprise users with slides.
  final bool onboardingCompleted;

  /// Optional evening nudge to finish the day's habits.
  final bool eveningReminderEnabled;

  /// Minutes since midnight for the evening nudge.
  final int eveningReminderMinutes;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? remindersEnabled,
    int? defaultReminderMinutes,
    bool? onboardingCompleted,
    bool? eveningReminderEnabled,
    int? eveningReminderMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      eveningReminderEnabled:
          eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderMinutes:
          eveningReminderMinutes ?? this.eveningReminderMinutes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.remindersEnabled == remindersEnabled &&
        other.defaultReminderMinutes == defaultReminderMinutes &&
        other.onboardingCompleted == onboardingCompleted &&
        other.eveningReminderEnabled == eveningReminderEnabled &&
        other.eveningReminderMinutes == eveningReminderMinutes;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    remindersEnabled,
    defaultReminderMinutes,
    onboardingCompleted,
    eveningReminderEnabled,
    eveningReminderMinutes,
  );
}
