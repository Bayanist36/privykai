import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:habit_tracker/app/app.dart';
import 'package:habit_tracker/core/utils/russian_plural.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/utils/name_counter.dart';

import '../../../../support/fake_habit_repository.dart';
import '../../../../support/fake_settings_repository.dart';

const int _maxNameLength = HabitListController.maxNameLength;

Widget _app(FakeHabitRepository repository) {
  return HabitTrackerApp(
    repository: repository,
    settingsRepository: FakeSettingsRepository(),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  group('NameCounter.label', () {
    test('reports the actual remainder for 1, 2, 5, 39 and 40 characters', () {
      expect(
        NameCounter.label(currentLength: 1, maxLength: _maxNameLength),
        'Осталось 39 символов',
      );
      expect(
        NameCounter.label(currentLength: 2, maxLength: _maxNameLength),
        'Осталось 38 символов',
      );
      expect(
        NameCounter.label(currentLength: 5, maxLength: _maxNameLength),
        'Осталось 35 символов',
      );
      expect(
        NameCounter.label(currentLength: 39, maxLength: _maxNameLength),
        'Остался 1 символ',
      );
      expect(
        NameCounter.label(currentLength: 40, maxLength: _maxNameLength),
        'Осталось 0 символов',
      );
    });

    test('uses Russian plural forms for the remainder', () {
      expect(RussianPlural.remainingCharacters(1), 'Остался 1 символ');
      expect(RussianPlural.remainingCharacters(2), 'Осталось 2 символа');
      expect(RussianPlural.remainingCharacters(5), 'Осталось 5 символов');
      expect(RussianPlural.remainingCharacters(11), 'Осталось 11 символов');
      expect(RussianPlural.remainingCharacters(21), 'Остался 21 символ');
      expect(RussianPlural.remainingCharacters(31), 'Остался 31 символ');
      expect(RussianPlural.remainingCharacters(0), 'Осталось 0 символов');
    });

    test('never reports a negative remainder', () {
      expect(
        NameCounter.label(currentLength: 41, maxLength: _maxNameLength),
        'Осталось 0 символов',
      );
    });
  });

  testWidgets('prefilled name shows the real remaining count (BUG-12)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_app(FakeHabitRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Пить воду'));
    await tester.pumpAndSettle();

    expect(find.text('Новая привычка'), findsOneWidget);
    expect(find.text('9/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Остался 31 символ'), findsOneWidget);
    expect(find.bySemanticsLabel('Остался 1 символ'), findsNothing);

    handle.dispose();
  });

  testWidgets('counter stays correct while typing and at both limits', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_app(FakeHabitRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить привычку'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField).first;

    await tester.enterText(field, 'Я');
    await tester.pump();
    expect(find.text('1/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Осталось 39 символов'), findsOneWidget);

    await tester.enterText(field, 'Бе');
    await tester.pump();
    expect(find.text('2/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Осталось 38 символов'), findsOneWidget);

    await tester.enterText(field, 'Вода!');
    await tester.pump();
    expect(find.text('5/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Осталось 35 символов'), findsOneWidget);

    await tester.enterText(field, 'А' * 39);
    await tester.pump();
    expect(find.text('39/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Остался 1 символ'), findsOneWidget);

    await tester.enterText(field, 'А' * 40);
    await tester.pump();
    expect(find.text('40/40'), findsOneWidget);
    expect(find.bySemanticsLabel('Осталось 0 символов'), findsOneWidget);

    handle.dispose();
  });
}
