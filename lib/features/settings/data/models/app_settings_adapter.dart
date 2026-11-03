import 'package:hive/hive.dart';

import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// Hand-written adapter for the single settings document.
///
/// `typeId` 14 is outside Hive's built-in 0–12 range. Ids 0 and 1 were
/// reserved by `FrameValueType` and silently corrupted settings (BUG-04).
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  static const int settingsTypeId = 14;

  @override
  final int typeId = settingsTypeId;

  static const int _fieldCount = 6;

  @override
  AppSettings read(BinaryReader reader) {
    // The count must be consumed once; repeating it in the loop condition
    // corrupts the field stream when a box is reopened.
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return AppSettings(
      themeMode: AppThemeMode.fromStorage(fields[0]),
      remindersEnabled: fields[1] as bool? ?? true,
      defaultReminderMinutes: fields[2] as int? ?? 8 * 60,
      onboardingCompleted: fields[3] as bool? ?? false,
      eveningReminderEnabled: fields[4] as bool? ?? false,
      eveningReminderMinutes:
          fields[5] as int? ?? AppSettings.defaultEveningMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings settings) {
    writer
      ..writeByte(_fieldCount)
      ..writeByte(0)
      ..write(settings.themeMode.storageValue)
      ..writeByte(1)
      ..write(settings.remindersEnabled)
      ..writeByte(2)
      ..write(settings.defaultReminderMinutes)
      ..writeByte(3)
      ..write(settings.onboardingCompleted)
      ..writeByte(4)
      ..write(settings.eveningReminderEnabled)
      ..writeByte(5)
      ..write(settings.eveningReminderMinutes);
  }
}
