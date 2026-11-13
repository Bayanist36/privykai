import 'package:flutter/foundation.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// Validated contents of a backup file.
@immutable
class BackupData {
  const BackupData({
    required this.habits,
    required this.settings,
    required this.exportedAt,
  });

  final List<Habit> habits;
  final AppSettings settings;
  final DateTime exportedAt;
}
