import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/app/app_info.dart';
import 'package:habit_tracker/features/settings/presentation/screens/privacy_policy_screen.dart';

const _expectedUrl =
    'https://Bayanist36.github.io/privykai-privacy/privykai-privacy.html';

Widget _screen() {
  return const MaterialApp(home: PrivacyPolicyScreen());
}

String _visibleText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .join('\n');
}

/// The screen is a long [ListView]; a tall surface builds every section so
/// assertions see the whole text at once.
Future<void> _renderFullList(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1080, 6000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_screen());
}

void main() {
  test('AppInfo mirrors release 1.1.1 and the published policy URL', () {
    expect(AppInfo.version, '1.1.1');
    expect(AppInfo.privacyPolicyEdition, '1.1');
    expect(AppInfo.privacyPolicyUrl, _expectedUrl);
    expect(AppInfo.hasPrivacyPolicyUrl, isTrue);
  });

  testWidgets('policy screen covers export, widget, notifications and backup', (
    tester,
  ) async {
    await _renderFullList(tester);

    final text = _visibleText(tester);
    expect(text, contains('Редакция 1.1'));
    expect(text, contains('офлайн'));
    expect(text, contains('Какие данные хранятся'));
    expect(text, contains('Экспорт и импорт'));
    expect(text, contains('Виджет главного экрана'));
    expect(text, contains('Уведомления'));
    expect(text, contains('Системное резервное копирование Android'));
    expect(text, contains('Удаление данных'));
  });

  testWidgets('no absolute "stays on this device" wording remains', (
    tester,
  ) async {
    await _renderFullList(tester);

    final text = _visibleText(tester);
    expect(text, isNot(contains('Все данные хранятся только')));
    expect(text, isNot(contains('не покидают устройство')));
  });

  testWidgets('full edition block shows the public URL without opening it', (
    tester,
  ) async {
    await _renderFullList(tester);

    final urlFinder = find.byType(SelectableText);
    final block = tester.widget<SelectableText>(urlFinder);
    expect(block.data, _expectedUrl);

    final text = _visibleText(tester);
    expect(text, contains('Полная редакция'));
    expect(text, contains('ссылке из карточки'));
  });
}
