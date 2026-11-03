import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:habit_tracker/app/app.dart';
import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_theme.dart';
import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';

import 'support/fake_habit_repository.dart';
import 'support/fake_settings_repository.dart';
import 'support/throwing_reminder_scheduler.dart';

Widget _app(
  FakeHabitRepository repository, {
  AppSettings settings = const AppSettings(onboardingCompleted: true),
}) {
  return HabitTrackerApp(
    repository: repository,
    settingsRepository: FakeSettingsRepository(settings),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('empty state is shown and a habit can be created', (
    tester,
  ) async {
    final repository = FakeHabitRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('Пока нет привычек'), findsOneWidget);

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();

    expect(find.text('Новая привычка'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Пить воду');
    await tester.pump();
    await tester.tap(find.text('Создать привычку'));
    await tester.pumpAndSettle();

    expect(find.text('Пить воду'), findsOneWidget);
    expect(repository.habits, hasLength(1));
  });

  testWidgets('today screen fits a 360x800 phone with habits', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Пить воду',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        reminderMinutes: 8 * 60,
        completedDates: [DateKey.from(DateTime.now())],
      ),
      Habit(
        id: 'habit-2',
        name: 'Читать 20 минут',
        iconKey: 'reading',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('Выполнено сегодня'), findsOneWidget);
    expect(find.text('Пить воду'), findsOneWidget);
    expect(find.text('Читать 20 минут'), findsOneWidget);
    expect(find.text('1 из 2'), findsWidgets);
    expect(find.byTooltip('Добавить привычку'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('habits scheduled for other weekdays are not listed today', (
    tester,
  ) async {
    final today = DateTime.now();
    final otherWeekday = today.weekday == 7 ? 1 : today.weekday + 1;
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Плавание',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        weekdaysMask: 1 << (otherWeekday - 1),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(find.text('На сегодня привычек нет'), findsOneWidget);
    expect(find.text('Плавание'), findsNothing);
    expect(
      find.text('В расписании 1 привычка, но не на сегодня.'),
      findsOneWidget,
    );
  });

  testWidgets('an existing habit can be edited from the action sheet', (
    tester,
  ) async {
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Пить воду',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Пить воду'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();

    expect(find.text('Изменить привычку'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Пить 2 литра');
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Пить 2 литра'), findsOneWidget);
    expect(repository.habits.single.name, 'Пить 2 литра');
  });

  testWidgets('first launch shows onboarding and skip opens Today', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(const AppSettings());
    final repository = FakeHabitRepository();

    await tester.pumpWidget(
      HabitTrackerApp(repository: repository, settingsRepository: settings),
    );
    await tester.pumpAndSettle();

    expect(find.text('Маленькие шаги.\nБольшие перемены.'), findsOneWidget);

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('Пока нет привычек'), findsOneWidget);
    expect(settings.settings.onboardingCompleted, isTrue);
  });

  testWidgets('settings switch the theme immediately and persist it', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    final repository = FakeHabitRepository();

    await tester.pumpWidget(
      HabitTrackerApp(repository: repository, settingsRepository: settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsWidgets);
    expect(find.text('Тема'), findsOneWidget);

    await tester.tap(find.text('Тема'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();

    expect(settings.settings.themeMode, AppThemeMode.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppPalette.dark.background);
  });

  testWidgets('weekday selection is persisted from the form', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeHabitRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Бег');
    await tester.pump();

    for (final label in <String>['Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(find.text('Пн'), findsWidgets);
    await tester.tap(find.text('Создать привычку'));
    await tester.pumpAndSettle();

    expect(repository.habits.single.weekdaysMask, 1 << 0);
    expect(repository.habits.single.name, 'Бег');
  });

  testWidgets('global reminder switch is saved', (tester) async {
    final settings = FakeSettingsRepository();
    await tester.pumpWidget(
      HabitTrackerApp(
        repository: FakeHabitRepository(),
        settingsRepository: settings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(settings.settings.remindersEnabled, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(settings.settings.remindersEnabled, isTrue);
    expect(
      find.text(
        'В дни по расписанию: один раз в день или каждые N часов. '
        'Вечернее напоминание приходит одно на весь список привычек.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Enter in the name field does not create a habit', (
    tester,
  ) async {
    final repository = FakeHabitRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Пить воду');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Новая привычка'), findsOneWidget);
    expect(repository.habits, isEmpty);

    await tester.tap(find.text('Создать привычку'));
    await tester.pumpAndSettle();

    expect(repository.habits.single.name, 'Пить воду');
  });

  testWidgets('interval reminder is saved from the form', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeHabitRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Пить воду');
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Каждые N часов'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Создать привычку'));
    await tester.pumpAndSettle();

    final habit = repository.habits.single;
    expect(habit.reminderMinutes, 8 * 60);
    expect(habit.reminderIntervalHours, 2);
    expect(habit.reminderWindowEndMinutes, 22 * 60);
    expect(habit.reminderTimesOfDay, hasLength(8));
    expect(find.text('Каждые 2 ч, 08:00–22:00'), findsOneWidget);
  });

  testWidgets('evening reminder switch is saved and shows its time', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    await tester.pumpWidget(
      HabitTrackerApp(
        repository: FakeHabitRepository(),
        settingsRepository: settings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Вечернее напоминание'), findsOneWidget);
    expect(find.text('Время вечернего напоминания'), findsNothing);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(settings.settings.eveningReminderEnabled, isTrue);
    expect(find.text('Время вечернего напоминания'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
  });

  testWidgets('reset asks twice, clears habits and restores system theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = FakeSettingsRepository(
      const AppSettings(
        themeMode: AppThemeMode.dark,
        onboardingCompleted: true,
      ),
    );
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Пить воду',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      HabitTrackerApp(repository: repository, settingsRepository: settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сбросить все данные'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить навсегда'));
    await tester.pumpAndSettle();

    expect(repository.habits, isEmpty);
    expect(settings.settings.themeMode, AppThemeMode.system);
    expect(find.text('Пока нет привычек'), findsOneWidget);
  });

  testWidgets('onboarding has three slides and finishes on the last one', (
    tester,
  ) async {
    final settings = FakeSettingsRepository(const AppSettings());
    await tester.pumpWidget(
      HabitTrackerApp(
        repository: FakeHabitRepository(),
        settingsRepository: settings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Работает\nбез интернета'), findsOneWidget);

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Напоминания вовремя'), findsOneWidget);

    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();

    expect(settings.settings.onboardingCompleted, isTrue);
    expect(find.text('Пока нет привычек'), findsOneWidget);
  });

  testWidgets('completing a habit shows the streak and undo reverts it', (
    tester,
  ) async {
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Пить воду',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Пить воду'));
    await tester.pumpAndSettle();

    expect(find.text('Выполнено. Серия: 1'), findsOneWidget);
    expect(find.text('Отменить'), findsOneWidget);
    expect(repository.habits.single.isCompletedToday, isTrue);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();

    expect(repository.habits.single.isCompletedToday, isFalse);
    expect(find.text('Выполнено. Серия: 1'), findsNothing);
  });

  testWidgets('unchecking a habit shows the uncheck snackbar', (tester) async {
    final repository = FakeHabitRepository([
      Habit(
        id: 'habit-1',
        name: 'Пить воду',
        iconKey: 'water',
        createdAt: DateTime(2026, 1, 1),
        completedDates: [DateKey.from(DateTime.now())],
      ),
    ]);

    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Пить воду'));
    await tester.pump();

    expect(find.text('Отметка снята'), findsOneWidget);
    expect(repository.habits.single.isCompletedToday, isFalse);
  });

  testWidgets('failed reminder plugin init is handled in the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeHabitRepository();
    await tester.pumpWidget(
      HabitTrackerApp(
        repository: repository,
        settingsRepository: FakeSettingsRepository(),
        reminderScheduler: ThrowingReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Вода');
    await tester.pump();

    final reminderSwitch = find.byType(Switch);
    expect(reminderSwitch, findsOneWidget);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();

    expect(
      find.text('Не удалось включить напоминание. Попробуйте ещё раз.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme dialog reports the selected option to TalkBack', (
    tester,
  ) async {
    await tester.pumpWidget(
      HabitTrackerApp(
        repository: FakeHabitRepository(),
        settingsRepository: FakeSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тема'));
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.text('Системная').last);
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('onboarding and empty Today fit a 320x640 phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      HabitTrackerApp(
        repository: FakeHabitRepository(),
        settingsRepository: FakeSettingsRepository(const AppSettings()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Маленькие шаги.\nБольшие перемены.'), findsOneWidget);

    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Пока нет привычек'), findsOneWidget);
  });
}
