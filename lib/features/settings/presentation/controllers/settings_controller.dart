import 'package:flutter/material.dart';

import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';

/// Owns persisted application preferences and exposes them to the widget tree.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = AppSettings.defaults;
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode => switch (_settings.themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      _settings = await _repository.load();
    } catch (error) {
      _errorMessage = 'Не удалось загрузить настройки.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    return _update(_settings.copyWith(themeMode: mode));
  }

  Future<void> setRemindersEnabled(bool enabled) {
    return _update(_settings.copyWith(remindersEnabled: enabled));
  }

  Future<void> setDefaultReminderMinutes(int minutes) {
    return _update(_settings.copyWith(defaultReminderMinutes: minutes));
  }

  Future<void> setEveningReminderEnabled(bool enabled) {
    return _update(_settings.copyWith(eveningReminderEnabled: enabled));
  }

  Future<void> setEveningReminderMinutes(int minutes) {
    return _update(_settings.copyWith(eveningReminderMinutes: minutes));
  }

  Future<void> completeOnboarding() {
    if (_settings.onboardingCompleted) {
      return Future<void>.value();
    }
    return _update(_settings.copyWith(onboardingCompleted: true));
  }

  /// Applies settings restored from a backup file.
  ///
  /// The value is persisted exactly as in the file; the import screen calls
  /// this only after the backup has been fully validated.
  Future<void> applyImported(AppSettings next) {
    return _update(next);
  }

  /// Restores reminder defaults and the system theme after a data reset.
  /// The onboarding flag survives, so the user returns to the empty Today
  /// screen instead of seeing the introduction again.
  Future<void> resetPreferences() {
    return _update(
      AppSettings.defaults.copyWith(
        onboardingCompleted: _settings.onboardingCompleted,
      ),
    );
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _notify();
  }

  Future<void> _update(AppSettings next) async {
    if (next == _settings) {
      return;
    }
    final previous = _settings;
    _settings = next;
    _errorMessage = null;
    _notify();
    try {
      await _repository.save(next);
    } catch (error) {
      _settings = previous;
      _errorMessage = 'Не удалось сохранить настройку.';
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
