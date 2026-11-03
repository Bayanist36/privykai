import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([
    AppSettings initial = const AppSettings(onboardingCompleted: true),
  ]) : settings = initial;

  AppSettings settings;
  bool failOnWrite = false;
  int saveCalls = 0;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings next) async {
    if (failOnWrite) {
      throw StateError('write failed');
    }
    saveCalls++;
    settings = next;
  }
}
