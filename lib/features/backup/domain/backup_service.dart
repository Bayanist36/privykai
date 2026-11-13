import 'dart:convert';

import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/backup/domain/backup_data.dart';
import 'package:habit_tracker/features/backup/domain/backup_exception.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

/// Versioned JSON backup of habits, completion history and settings.
///
/// The format is intentionally plain JSON with a stable `schemaVersion`, so a
/// user can move data between devices without a backend and a future release
/// can migrate old files explicitly. Validation happens before anything is
/// written to storage: a broken or foreign file can never wipe local data.
class BackupService {
  const BackupService();

  static const String format = 'pryvykai-backup';
  static const int schemaVersion = 1;
  static const Set<int> supportedSchemaVersions = <int>{schemaVersion};

  String encode({
    required List<Habit> habits,
    required AppSettings settings,
    DateTime? exportedAt,
  }) {
    final document = <String, Object?>{
      'format': format,
      'schemaVersion': schemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'settings': _encodeSettings(settings),
      'habits': [for (final habit in habits) _encodeHabit(habit)],
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  /// Parses and validates [source].
  ///
  /// Throws a [BackupException] with a user-facing message when the file is
  /// not valid JSON, belongs to another app, has an unsupported schema or
  /// contains a damaged habit.
  BackupData decode(String source) {
    if (source.trim().isEmpty) {
      throw const BackupException('Файл пустой.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupException('Файл повреждён: не удалось прочитать JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('Неизвестный формат файла.');
    }

    if (decoded['format'] != format) {
      throw const BackupException('Это не файл резервной копии «Привыкай».');
    }

    final version = decoded['schemaVersion'];
    if (version is! int) {
      throw const BackupException('В файле нет версии схемы.');
    }
    if (!supportedSchemaVersions.contains(version)) {
      throw BackupException(
        version > schemaVersion
            ? 'Файл создан в более новой версии приложения '
                  '(схема $version). Обновите приложение.'
            : 'Версия файла ($version) не поддерживается.',
      );
    }

    final habitsRaw = decoded['habits'];
    if (habitsRaw is! List) {
      throw const BackupException('В файле нет списка привычек.');
    }

    final habits = <Habit>[];
    final ids = <String>{};
    for (var index = 0; index < habitsRaw.length; index++) {
      final habit = _decodeHabit(habitsRaw[index], index + 1);
      if (!ids.add(habit.id)) {
        throw BackupException(
          'Привычка №${index + 1}: повторяющийся идентификатор.',
        );
      }
      habits.add(habit);
    }
    habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return BackupData(
      habits: List<Habit>.unmodifiable(habits),
      settings: _decodeSettings(decoded['settings']),
      exportedAt: _parseDate(decoded['exportedAt']) ?? DateTime.now(),
    );
  }

  Map<String, Object?> _encodeHabit(Habit habit) {
    return <String, Object?>{
      'id': habit.id,
      'name': habit.name,
      'iconKey': habit.iconKey,
      'colorKey': habit.colorKey,
      'weekdaysMask': habit.weekdaysMask,
      'createdAt': habit.createdAt.toUtc().toIso8601String(),
      'reminderMinutes': habit.reminderMinutes,
      'reminderIntervalHours': habit.reminderIntervalHours,
      'reminderWindowEndMinutes': habit.reminderWindowEndMinutes,
      'completedDates': habit.completedDates,
    };
  }

  Map<String, Object?> _encodeSettings(AppSettings settings) {
    return <String, Object?>{
      'themeMode': settings.themeMode.storageValue,
      'remindersEnabled': settings.remindersEnabled,
      'defaultReminderMinutes': settings.defaultReminderMinutes,
      'onboardingCompleted': settings.onboardingCompleted,
      'eveningReminderEnabled': settings.eveningReminderEnabled,
      'eveningReminderMinutes': settings.eveningReminderMinutes,
    };
  }

  Habit _decodeHabit(Object? raw, int position) {
    if (raw is! Map<String, dynamic>) {
      throw BackupException('Привычка №$position: неверный формат.');
    }

    final id = _requiredString(raw['id'], position, 'идентификатор');
    final name = _requiredString(raw['name'], position, 'название').trim();
    if (name.isEmpty) {
      throw BackupException('Привычка №$position: пустое название.');
    }
    if (name.runes.length > Habit.maxNameLength) {
      throw BackupException(
        'Привычка №$position: название длиннее ${Habit.maxNameLength} символов.',
      );
    }

    final weekdaysMask = raw['weekdaysMask'];
    if (weekdaysMask is! int || !Weekdays.isValid(weekdaysMask)) {
      throw BackupException(
        'Привычка №$position: неверное расписание по дням недели.',
      );
    }

    final createdAt = _parseDate(raw['createdAt']);
    if (createdAt == null) {
      throw BackupException('Привычка №$position: неверная дата создания.');
    }

    final reminderMinutes = _optionalMinutes(raw['reminderMinutes']);
    final interval = _optionalInt(
      raw['reminderIntervalHours'],
      min: Habit.minIntervalHours,
      max: Habit.maxIntervalHours,
    );
    final windowEnd =
        _optionalInt(
          raw['reminderWindowEndMinutes'],
          min: 0,
          max: 23 * 60 + 59,
        ) ??
        Habit.defaultWindowEndMinutes;

    final completedDates = _decodeCompletedDates(
      raw['completedDates'],
      position,
    );

    return Habit(
      id: id,
      name: name,
      iconKey: _optionalString(raw['iconKey']) ?? 'other',
      colorKey: _optionalString(raw['colorKey']) ?? Habit.defaultColorKey,
      weekdaysMask: weekdaysMask,
      createdAt: createdAt.toLocal(),
      reminderMinutes: reminderMinutes,
      reminderIntervalHours: reminderMinutes == null ? null : interval,
      reminderWindowEndMinutes: windowEnd,
      completedDates: completedDates,
    );
  }

  List<String> _decodeCompletedDates(Object? raw, int position) {
    if (raw == null) {
      return const <String>[];
    }
    if (raw is! List) {
      throw BackupException('Привычка №$position: история отметок повреждена.');
    }
    final dates = <String>{};
    for (final value in raw) {
      final parsed = value is String ? DateKey.parse(value) : null;
      // DateKey.parse normalises out-of-range values (month 13 becomes next
      // year), so require the key to survive a round-trip unchanged.
      if (value is! String ||
          parsed == null ||
          DateKey.from(parsed) != value) {
        throw BackupException(
          'Привычка №$position: неверная дата в истории отметок.',
        );
      }
      dates.add(value);
    }
    return dates.toList()..sort();
  }

  AppSettings _decodeSettings(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return AppSettings.defaults;
    }
    return AppSettings(
      themeMode: AppThemeMode.fromStorage(raw['themeMode']),
      remindersEnabled: _boolOr(raw['remindersEnabled'], true),
      defaultReminderMinutes:
          _optionalMinutes(raw['defaultReminderMinutes']) ?? 8 * 60,
      onboardingCompleted: _boolOr(raw['onboardingCompleted'], false),
      eveningReminderEnabled: _boolOr(raw['eveningReminderEnabled'], false),
      eveningReminderMinutes:
          _optionalMinutes(raw['eveningReminderMinutes']) ??
          AppSettings.defaultEveningMinutes,
    );
  }

  String _requiredString(Object? value, int position, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw BackupException('Привычка №$position: неверный $field.');
    }
    return value;
  }

  String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value;
  }

  bool _boolOr(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  int? _optionalMinutes(Object? value) =>
      _optionalInt(value, min: 0, max: 23 * 60 + 59);

  int? _optionalInt(Object? value, {required int min, required int max}) {
    if (value is! int || value < min || value > max) {
      return null;
    }
    return value;
  }

  DateTime? _parseDate(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
