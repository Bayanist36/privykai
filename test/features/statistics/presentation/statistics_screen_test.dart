import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:habit_tracker/app/app.dart';
import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

import '../../../support/fake_habit_repository.dart';
import '../../../support/fake_settings_repository.dart';

Widget _app(
  FakeHabitRepository repository, {
  AppSettings settings = const AppSettings(onboardingCompleted: true),
}) {
  return HabitTrackerApp(
    repository: repository,
    settingsRepository: FakeSettingsRepository(settings),
  );
}

Future<void> _openStats(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.bar_chart_outlined));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('empty statistics state offers to add a habit', (tester) async {
    await tester.pumpWidget(_app(FakeHabitRepository()));
    await tester.pumpAndSettle();

    await _openStats(tester);

    expect(find.text('Статистика'), findsWidgets);
    expect(find.text('Пока нет привычек'), findsOneWidget);
    expect(find.text('Добавить привычку'), findsOneWidget);
  });

  testWidgets('statistics shows 7-day summary and per-habit streaks', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: now,
        completedDates: [DateKey.from(now)],
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _openStats(tester);

    expect(find.text('За последние 7 дней'), findsOneWidget);
    expect(find.text('1 из 1'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('По привычкам'), findsOneWidget);
    expect(find.text('30 дней'), findsOneWidget);
    expect(find.text('Вода'), findsOneWidget);
    expect(find.text('Серия 1 · лучшая 1'), findsOneWidget);
  });

  testWidgets('habits without completions show zeroes and a hint', (
    tester,
  ) async {
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Чтение',
        iconKey: 'reading',
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await _openStats(tester);

    expect(find.text('0 из 1'), findsOneWidget);
    expect(find.text('Серия 0 · лучшая 0'), findsOneWidget);
    expect(
      find.text('Отметьте первую привычку — здесь появится прогресс.'),
      findsOneWidget,
    );
  });

  testWidgets('statistics renders in the dark palette', (tester) async {
    final now = DateTime.now();
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Вода',
        iconKey: 'water',
        createdAt: now,
        completedDates: [DateKey.from(now)],
      ),
    ]);

    await tester.pumpWidget(
      _app(
        repository,
        settings: const AppSettings(
          themeMode: AppThemeMode.dark,
          onboardingCompleted: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openStats(tester);

    expect(find.text('За последние 7 дней'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
