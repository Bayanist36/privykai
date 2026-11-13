// SUK-10 asset generator: renders real app screens off-screen at 1080 x 2400
// (360 x 800 dp, DPR 3) and writes PNGs used by the RuStore compositions.
//
// This is a design/QA tool, not part of the app. Run:
//   flutter test tool/suk10_screenshots_test.dart
//
// Output: design/store/app/{today,stats,form,settings}.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_shell.dart';
import 'package:habit_tracker/app/theme/app_theme.dart';
import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';

const _flutterFonts = r'D:\dev\flutter\bin\cache\artifacts\material_fonts';
const _emojiFont = r'C:\Windows\Fonts\seguiemj.ttf';

final _outDir = Directory('design/store/app');

class _FakeHabitRepository implements HabitRepository {
  _FakeHabitRepository(this.habits);

  final List<Habit> habits;

  @override
  Future<void> delete(String id) async {
    habits.removeWhere((habit) => habit.id == id);
  }

  @override
  Future<void> deleteAll() async => habits.clear();

  @override
  Future<List<Habit>> getAll() async => List<Habit>.of(habits);

  @override
  Future<void> save(Habit habit) async {
    final index = habits.indexWhere((item) => item.id == habit.id);
    if (index >= 0) {
      habits[index] = habit;
    } else {
      habits.add(habit);
    }
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings(onboardingCompleted: true);

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings next) async => settings = next;
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Roboto', <String>[
    '$_flutterFonts\\roboto-regular.ttf',
    '$_flutterFonts\\roboto-medium.ttf',
    '$_flutterFonts\\roboto-bold.ttf',
  ]);
  await _loadFont('MaterialIcons', <String>[
    '$_flutterFonts\\materialicons-regular.otf',
  ]);
  if (File(_emojiFont).existsSync()) {
    await _loadFont('Segoe UI Emoji', <String>[_emojiFont]);
  }
}

DateTime get _today => Habit.dateOnly(DateTime.now());

List<String> _completedBack(Habit habit, int count, {bool includeToday = false}) {
  final result = <String>[];
  var cursor = _today;
  if (!includeToday) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  while (result.length < count) {
    if (habit.isScheduledOn(cursor)) {
      result.add(DateKey.from(cursor));
    }
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return result;
}

Habit _habit({
  required String id,
  required String name,
  required String iconKey,
  required String colorKey,
  int weekdaysMask = Weekdays.everyDayMask,
  int? reminderMinutes,
  int streak = 0,
  bool doneToday = false,
}) {
  final base = Habit(
    id: id,
    name: name,
    iconKey: iconKey,
    colorKey: colorKey,
    weekdaysMask: weekdaysMask,
    createdAt: DateTime(_today.year, _today.month, _today.day - 120),
    reminderMinutes: reminderMinutes,
  );
  return base.copyWith(
    completedDates: _completedBack(base, streak, includeToday: doneToday),
  );
}

List<Habit> _demoHabits() {
  return <Habit>[
    _habit(
      id: 'water',
      name: 'Пить воду',
      iconKey: 'water',
      colorKey: 'green',
      reminderMinutes: 9 * 60,
      streak: 13,
      doneToday: true,
    ),
    _habit(
      id: 'reading',
      name: 'Читать 20 минут',
      iconKey: 'reading',
      colorKey: 'blue',
      reminderMinutes: 21 * 60 + 30,
      streak: 12,
    ),
    _habit(
      id: 'run',
      name: 'Пробежка',
      iconKey: 'run',
      colorKey: 'coral',
      weekdaysMask: (1 << 0) | (1 << 2) | (1 << 4),
      streak: 6,
      doneToday: true,
    ),
    _habit(
      id: 'meditation',
      name: 'Медитация',
      iconKey: 'meditation',
      colorKey: 'violet',
      streak: 5,
      doneToday: true,
    ),
    _habit(
      id: 'nutrition',
      name: 'Питание',
      iconKey: 'nutrition',
      colorKey: 'teal',
      weekdaysMask: (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4),
      reminderMinutes: 12 * 60 + 30,
      streak: 1,
    ),
  ];
}

ThemeData _screenshotTheme({bool dark = false}) {
  final base = dark ? AppTheme.dark : AppTheme.light;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const <String>['Segoe UI Emoji'],
    ),
  );
}

Widget _host({
  required Widget home,
  required List<Habit> habits,
  bool dark = false,
}) {
  final habitsRepo = _FakeHabitRepository(habits);
  final settingsRepo = _FakeSettingsRepository();
  return MultiProvider(
    providers: [
      Provider<ReminderScheduler>.value(value: const NoopReminderScheduler()),
      ChangeNotifierProvider<HabitListController>(
        create: (_) => HabitListController(habitsRepo)..load(),
      ),
      ChangeNotifierProvider<SettingsController>(
        create: (_) => SettingsController(settingsRepo)..load(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _screenshotTheme(dark: dark),
      locale: const Locale('ru'),
      supportedLocales: const <Locale>[Locale('ru')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  );
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final list = find.byType(ListView);
  for (var attempt = 0; attempt < 10 && target.evaluate().isEmpty; attempt++) {
    await tester.drag(list, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
  final screenHeight =
      tester.view.physicalSize.height / tester.view.devicePixelRatio;
  if (tester.getCenter(target.first).dy > screenHeight - 130) {
    await tester.drag(list, const Offset(0, -110));
    await tester.pumpAndSettle();
  }
}

Future<void> _enableIntervalReminder(WidgetTester tester) async {
  await _reveal(tester, find.byType(Switch));
  await tester.tap(find.byType(Switch).first);
  await tester.pumpAndSettle();
  await _reveal(tester, find.text('Каждые N часов'));
  await tester.tap(find.text('Каждые N часов'));
  await tester.pumpAndSettle();
  await _reveal(tester, find.text('До'));
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync(pixelRatio: 3);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  final bytes = data!.buffer.asUint8List();
  _outDir.createSync(recursive: true);
  File('${_outDir.path}/$name.png').writeAsBytesSync(bytes);
}

Future<void> _pump(
  WidgetTester tester,
  Widget app,
  GlobalKey key,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(key: key, child: app),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // AppShell listens to widget taps; there is no Android host in a widget
    // test, so answer the plugin channel instead of letting it throw.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget/updates'), (
          MethodCall call,
        ) async => null);
    await initializeDateFormatting('ru');
    await _loadFonts();
  });

  testWidgets('render store screenshots', (tester) async {
    final habits = _demoHabits();

    // 1. Today, light theme.
    final todayKey = GlobalKey();
    await _pump(tester, _host(home: const AppShell(), habits: habits), todayKey);
    await _capture(tester, todayKey, 'today');

    // 2. Statistics tab.
    final statsKey = GlobalKey();
    await _pump(tester, _host(home: const AppShell(), habits: habits), statsKey);
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, statsKey, 'stats');

    // 3. New habit form prefilled.
    final formKey = GlobalKey();
    await _pump(
      tester,
      _host(
        home: const HabitFormScreen(
          initialName: 'Медитация',
          initialIconKey: 'meditation',
          initialColorKey: 'violet',
        ),
        habits: habits,
      ),
      formKey,
    );
    await _capture(tester, formKey, 'form');

    // 3b. Interval reminder block for the v1.1 store card.
    final intervalKey = GlobalKey();
    await _pump(
      tester,
      _host(
        home: const HabitFormScreen(
          initialName: 'Пить воду',
          initialIconKey: 'water',
          initialColorKey: 'green',
        ),
        habits: habits,
      ),
      intervalKey,
    );
    await _enableIntervalReminder(tester);
    await _capture(tester, intervalKey, 'form-interval');

    // 4. Settings tab.
    final settingsKey = GlobalKey();
    await _pump(tester, _host(home: const AppShell(), habits: habits), settingsKey);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, settingsKey, 'settings');

    // 5. Dark theme evidence for the visual review.
    final darkKey = GlobalKey();
    await _pump(
      tester,
      _host(home: const AppShell(), habits: habits, dark: true),
      darkKey,
    );
    await _capture(tester, darkKey, 'today-dark');

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _capture(tester, darkKey, 'stats-dark');
  });
}
