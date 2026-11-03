import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// Persistence boundary for application preferences.
abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
