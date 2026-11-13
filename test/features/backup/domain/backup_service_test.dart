import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/backup/domain/backup_exception.dart';
import 'package:habit_tracker/features/backup/domain/backup_service.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

import '../../../support/fake_habit_repository.dart';

Habit _habit() {
  return Habit(
    id: 'habit-water',
    name: 'Пить воду',
    iconKey: 'water',
    colorKey: 'green',
    weekdaysMask: 0x15,
    createdAt: DateTime.utc(2026, 1, 2, 7, 30),
    reminderMinutes: 8 * 60,
    reminderIntervalHours: 2,
    reminderWindowEndMinutes: 22 * 60,
    completedDates: const <String>['2026-11-01', '2026-11-02'],
  );
}

const _settings = AppSettings(
  themeMode: AppThemeMode.dark,
  remindersEnabled: false,
  defaultReminderMinutes: 9 * 60,
  onboardingCompleted: true,
  eveningReminderEnabled: true,
  eveningReminderMinutes: 21 * 60,
);

void main() {
  const service = BackupService();

  String encodeDocument({int schemaVersion = 1}) {
    final document = jsonDecode(
      service.encode(
        habits: <Habit>[_habit()],
        settings: _settings,
        exportedAt: DateTime.utc(2026, 11, 3),
      ),
    ) as Map<String, dynamic>;
    document['schemaVersion'] = schemaVersion;
    return jsonEncode(document);
  }

  test(
    'export then import restores habits and history on a clean store',
    () async {
      final source = service.encode(
        habits: <Habit>[_habit()],
        settings: _settings,
        exportedAt: DateTime.utc(2026, 11, 3),
      );
      final document = jsonDecode(source) as Map<String, dynamic>;

      expect(document['format'], BackupService.format);
      expect(document['schemaVersion'], BackupService.schemaVersion);
      expect(document['habits'], hasLength(1));

    final restored = service.decode(source);
    final imported = restored.habits.single;
    final original = _habit();
    expect(imported.id, original.id);
    expect(imported.name, original.name);
    expect(imported.iconKey, original.iconKey);
    expect(imported.colorKey, original.colorKey);
    expect(imported.weekdaysMask, original.weekdaysMask);
    expect(imported.reminderMinutes, original.reminderMinutes);
    expect(imported.reminderIntervalHours, original.reminderIntervalHours);
    expect(
      imported.reminderWindowEndMinutes,
      original.reminderWindowEndMinutes,
    );
    expect(imported.completedDates, original.completedDates);
    expect(imported.createdAt.isAtSameMomentAs(original.createdAt), isTrue);
    expect(restored.settings, _settings);

      final repository = FakeHabitRepository();
      final controller = HabitListController(repository);
      await controller.load();
      final applied = await controller.replaceAll(restored.habits.toList());

      expect(applied, isTrue);
      final saved = await repository.getAll();
      expect(saved, hasLength(1));
      expect(saved.single.completedDates, <String>['2026-11-01', '2026-11-02']);
      expect(saved.single.reminderIntervalHours, 2);
    },
  );

  test('malformed JSON fails with a readable message', () {
    expect(
      () => service.decode('{"format": "pryvykai-backup",'),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('повреждён'),
        ),
      ),
    );
  });

  test('a newer schema version is rejected without touching storage', () {
    expect(
      () => service.decode(encodeDocument(schemaVersion: 99)),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('более новой'),
        ),
      ),
    );
  });

  test('an unsupported older schema version is rejected', () {
    expect(
      () => service.decode(encodeDocument(schemaVersion: 0)),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('не поддерживается'),
        ),
      ),
    );
  });

  test('a file from another app is rejected', () {
    final source = jsonEncode(<String, Object?>{
      'format': 'another-app',
      'schemaVersion': 1,
      'habits': <Object?>[],
    });

    expect(
      () => service.decode(source),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('не файл резервной копии'),
        ),
      ),
    );
  });

  test('a damaged habit is reported with its position', () {
    final document = jsonDecode(encodeDocument()) as Map<String, dynamic>;
    final habits = document['habits'] as List<dynamic>;
    final habit = habits.single as Map<String, dynamic>;
    habit['completedDates'] = <String>['2026-13-99'];

    expect(
      () => service.decode(jsonEncode(document)),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('Привычка №1'),
        ),
      ),
    );
  });

  test('an empty backup document is valid', () {
    final source = service.encode(
      habits: const <Habit>[],
      settings: AppSettings.defaults,
    );

    final restored = service.decode(source);

    expect(restored.habits, isEmpty);
    expect(restored.settings, AppSettings.defaults);
  });
}
