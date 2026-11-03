import 'package:habit_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<AppSettings> load() => _localDataSource.load();

  @override
  Future<void> save(AppSettings settings) => _localDataSource.save(settings);
}
