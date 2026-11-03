import 'package:hive/hive.dart';

import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// One Hive document keyed `app` inside the `settings` box.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._box, {this.fallback = AppSettings.defaults});

  static const String _key = 'app';

  final Box<AppSettings> _box;

  /// Used on first start and for installations that predate settings storage.
  final AppSettings fallback;

  Future<AppSettings> load() async => _box.get(_key) ?? fallback;

  Future<void> save(AppSettings settings) async {
    await _box.put(_key, settings);
  }
}
