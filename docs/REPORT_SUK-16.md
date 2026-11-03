# SUK-16. Исправление BUG-12: счётчик символов

**Дата:** 25 октября 2026
**Автор:** Flutter-разработчик
**Источник:** повторный QA SUK-14 (`qa-report`, BUG-12, Minor)
**Статус:** исправлено, автотесты и `scripts/verify.ps1` зелёные, debug APK
собран. Release-ключ не создавался — ждём решения владельца.

## 1. Итог

- Причина BUG-12 — не арифметика остатка, а встроенная русская локализация
  Flutter: форма `remainingTextFieldCharacterCountOne` жёстко содержит строку
  «Остался 1 символ» без подстановки числа. ICU выбирает форму `one` для всех
  чисел, оканчивающихся на 1 (кроме 11–14), поэтому при названии «Пить воду»
  (9 символов, остаток 31) accessibility-подпись счётчика читалась как
  «Остался 1 символ».
- Счётчик формы теперь собирается приложением: видимая часть остаётся
  `длина/40` по дизайн-спеке, а accessibility-подпись содержит фактический
  остаток и правильное склонение.
- `scripts/verify.ps1`: **89 тестов зелёные**, `flutter analyze` — `No issues
  found!`, debug APK собирается.

## 2. Причина

`TextFormField(maxLength: 40)` рисует встроенный счётчик Flutter. Его видимый
текст — `9/40` (корректный), а семантическая подпись для TalkBack/uiautomator
берётся из `MaterialLocalizations.remainingTextFieldCharacterCount(remaining)`.
В `material_ru.arb`:

```json
"remainingTextFieldCharacterCountOne": "Остался 1 символ",
"remainingTextFieldCharacterCountOther": "Осталось $remainingCount символа"
```

Строка формы `one` не содержит `$remainingCount`, поэтому номер не
подставляется. Для остатка 31 (`31 % 10 == 1`, `31 % 100 != 11`) выбирается
именно `one` → «Остался 1 символ». Для остатка 2/5/39 результат был верным,
но форма `other` («символа») грамматически неверна для 5 и 39 — это тоже
закрыто собственным форматтером.

Off-by-one отсутствует: остаток считается как `maxLength - currentLength`,
как и во встроенном счётчике, и ограничивается диапазоном `0..maxLength`.

## 3. Изменения

- `lib/core/utils/russian_plural.dart` — `RussianPlural.symbols()` и
  `RussianPlural.remainingCharacters()`: «Остался 1 символ», «Осталось 2
  символа», «Осталось 5 символов», «Остался 31 символ», «Осталось 0 символов».
- `lib/features/habits/presentation/utils/name_counter.dart` — сборка счётчика:
  видимый текст `currentLength/maxLength` (стиль 12/16, вес 500) и
  семантическая подпись с фактическим остатком.
- `lib/features/habits/presentation/screens/habit_form_screen.dart` —
  `buildCounter: NameCounter.build` у поля названия. Лимит 40, валидация и
  сохранение не менялись.
- `test/features/habits/presentation/utils/name_counter_test.dart` — 5 новых
  тестов (3 unit + 2 widget).

## 4. Покрытие критериев приёмки

| Критерий | Проверка |
|---|---|
| Счётчик корректен для 1, 2, 5, 39, 40 символов | `NameCounter.label` для длин 1/2/5/39/40 → остатки 39/38/35/1/0, а также widget-тест с вводом 1/2/5/39/40 символов |
| Предзаполненная форма («Пить воду») | widget-тест: видимый `9/40`, подпись «Остался 31 символ», строки «Остался 1 символ» нет |
| Склонения | unit-тесты для остатков 0, 1, 2, 5, 11, 21, 31, 39 |
| Отрицательный остаток | `currentLength: 41` → «Осталось 0 символов» |
| Добавлен тест | 5 тестов в `name_counter_test.dart` |
| `scripts/verify.ps1` зелёный | 89 тестов, `No issues found!`, debug APK собран |
| Debug APK собирается | `build/app/outputs/flutter-apk/app-debug.apk`, 150,72 МБ, SHA-256 `EF70F8F2…825D22` |
| Ключ подписи не генерировать | не создавался; `android/key.properties` и keystore не трогались |

## 5. Команды

```powershell
pwsh -NoProfile -File scripts/verify.ps1
```

Скрипт выполняет `flutter pub get`, `flutter test`, `scripts/analyze.ps1`
(зеркало в `C:\Users\Public\habit_tracker_verify` из-за не-ASCII пути) и
`scripts/build_debug_apk.ps1`.

## 6. Известные ограничения

- Проверка выполнена автотестами и сборкой debug APK; на эмуляторе/устройстве
  в этой задаче не прогонялась.
- Видимый счётчик оставлен в формате `9/40` по `design/DESIGN_SPEC.md`; текст
  «Осталось N символов» отдаётся как accessibility-подпись. Если QA считывает
  счётчик через `uiautomator dump`, там теперь будет корректный остаток.
- Release-подпись и BUG-03/BUG-08 не входят в эту задачу и остаются
  блокерами публикации по отчёту SUK-14.
