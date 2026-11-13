// SUK-20 design acceptance: renders v1.1 form/settings states at the
// smallest supported size (320 x 640 dp) and with enlarged text, and records
// any RenderFlex overflow. Output PNGs go to design/exports/review/.
//
// Run:
//   flutter test design/tools/design_review_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/theme/app_theme.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';
import 'package:habit_tracker/features/settings/presentation/screens/settings_screen.dart';

const _flutterFonts = r'D:\dev\flutter\bin\cache\artifacts\material_fonts';
const _emojiFont = r'C:\Windows\Fonts\seguiemj.ttf';

final _outDir = Directory('design/exports/review');

class _FakeHabitRepository implements HabitRepository {
  _FakeHabitRepository(this.habits);

  final List<Habit> habits;

  @override
  Future<void> delete(String id) async => habits.removeWhere((h) => h.id == id);

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
  _FakeSettingsRepository(this.settings);

  AppSettings settings;

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

ThemeData _theme({bool dark = false}) {
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
  required double textScale,
  bool dark = false,
  AppSettings settings = const AppSettings(onboardingCompleted: true),
  List<Habit> habits = const <Habit>[],
}) {
  return MultiProvider(
    providers: [
      Provider<ReminderScheduler>.value(value: const NoopReminderScheduler()),
      ChangeNotifierProvider<HabitListController>(
        create: (_) => HabitListController(_FakeHabitRepository(habits.toList()))
          ..load(),
      ),
      ChangeNotifierProvider<SettingsController>(
        create: (_) => SettingsController(_FakeSettingsRepository(settings))
          ..load(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(dark: dark),
      locale: const Locale('ru'),
      supportedLocales: const <Locale>[Locale('ru')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: home,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget app,
  GlobalKey key, {
  Size size = const Size(320, 640),
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(key: key, child: app));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = boundary.toImageSync(pixelRatio: 2);
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  _outDir.createSync(recursive: true);
  File('${_outDir.path}/$name.png').writeAsBytesSync(
    data!.buffer.asUint8List(),
  );
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final list = find.byType(ListView);
  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
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

void _expectNoOverflow(WidgetTester tester, String label) {
  final error = tester.takeException();
  if (error != null) {
    fail('$label: $error');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru');
    await _loadFonts();
  });

  for (final scale in <double>[1.0, 1.3, 2.0]) {
    testWidgets('form interval reminder 320x640 textScale $scale', (
      tester,
    ) async {
      final key = GlobalKey();
      await _pump(
        tester,
        _host(
          home: const HabitFormScreen(
            initialName: 'Пить воду',
            initialIconKey: 'water',
            initialColorKey: 'green',
          ),
          textScale: scale,
        ),
        key,
      );
      _expectNoOverflow(tester, 'form initial');
      await _enableIntervalReminder(tester);
      await _capture(tester, key, 'form-interval-320x640-x$scale');
      _expectNoOverflow(tester, 'form interval scale $scale');

      // The save button must stay reachable and the hint must mention the
      // interval window.
      expect(find.text('Создать привычку'), findsOneWidget);
      expect(
        find.textContaining('Напоминание повторяется каждые'),
        findsOneWidget,
      );
    });
  }

  for (final scale in <double>[1.0, 2.0]) {
    testWidgets('settings evening reminder 320x640 textScale $scale', (
      tester,
    ) async {
      final key = GlobalKey();
      await _pump(
        tester,
        _host(
          home: const SettingsScreen(onDataReset: _noop),
          textScale: scale,
          settings: const AppSettings(
            onboardingCompleted: true,
            eveningReminderEnabled: true,
            eveningReminderMinutes: 20 * 60,
          ),
        ),
        key,
      );
      _expectNoOverflow(tester, 'settings initial');
      await tester.scrollUntilVisible(
        find.text('Время вечернего напоминания'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      _expectNoOverflow(tester, 'settings evening scale $scale');
      expect(find.text('Вечернее напоминание'), findsOneWidget);
      expect(find.text('20:00'), findsOneWidget);
      await _capture(tester, key, 'settings-evening-320x640-x$scale');
    });
  }

  testWidgets('form interval on 360x800 for store screenshot', (tester) async {
    final key = GlobalKey();
    await _pump(
      tester,
      _host(
        home: const HabitFormScreen(
          initialName: 'Пить воду',
          initialIconKey: 'water',
          initialColorKey: 'green',
        ),
        textScale: 1,
      ),
      key,
      size: const Size(360, 800),
    );
    await _enableIntervalReminder(tester);
    _expectNoOverflow(tester, 'form interval 360x800');
    await _capture(tester, key, 'form-interval-360x800');
  });
}

void _noop() {}
