# SUK-23 · v1.1 RC2 — отчёт разработчика

**Дата:** 3 ноября 2026  
**Сборка:** 1.1.0+2, versionName `1.1.0`, versionCode `2002` (arm64) / `1002` (armeabi-v7a)  
**Статус:** готово к повторному QA и UI-приёмке

## 1. Что сделано

### 1.1. Экспорт/импорт JSON (QA-18-01)

- `lib/features/backup/domain/backup_service.dart` — версионированный JSON
  (`format: pryvykai-backup`, `schemaVersion: 1`), привычки + история отметок +
  настройки.
- `lib/features/backup/data/backup_file_gateway.dart` — выбор файла
  (`file_picker`), запись во временный каталог (`path_provider`) и системный
  шаринг (`share_plus`).
- Настройки → «Данные»: строки «Экспорт» и «Импорт».
- Импорт: валидация формата, версии схемы, каждого поля привычки и дат истории
  до любой записи в Hive. Битый/чужой файл даёт русское сообщение, данные не
  меняются. Пустой backup (0 привычек) считается валидным.
- Импорт заменяет привычки и настройки после подтверждения, пересоздаёт
  напоминания и обновляет виджет.
- Тесты: `test/features/backup/domain/backup_service_test.dart` — round-trip на
  чистом хранилище, битый JSON, новая/старая версия схемы, чужой формат,
  повреждённая привычка, пустой backup.

### 1.2. Нативный виджет (QA-18-02, D-06, QA-18-04)

- `android/app/src/main/kotlin/.../HabitWidgetProvider.kt` — `AppWidgetProvider`
  на `RemoteViews`, без Flutter-рендера.
- Layout `widget_habit_2x1.xml` (A: «СЕГОДНЯ», «N из M», остаток, процент,
  полоса), `widget_habit_4x2.xml` (заголовок, прогресс, 2–3 строки, футер) и
  `widget_habit_row.xml`.
- `values/colors.xml` + `values-night/colors.xml` по палитре
  `design/WIDGET_SPEC_v1.0.md` §5.
- `xml/habit_widget_info.xml`: `minWidth 110dp`, `minHeight 40dp`,
  `targetCell 2×1`, `resizeMode`, `updatePeriodMillis=0`, `previewLayout`,
  описание для галереи.
- `AndroidManifest.xml`: receiver `HabitWidgetProvider` с `APPWIDGET_UPDATE`,
  `DATE_CHANGED`, `TIME_SET`, `TIMEZONE_CHANGED`, `BOOT_COMPLETED` и
  `meta-data android.appwidget.provider`.
- Состояния: `empty`, `active`, `done`, `streak`, `stale` (по `widget_date`).
  Длинное имя обрезается до 16 символов с `…`, строки — `maxLines=1`.
- Тап по любой точке — `PendingIntent` на `MainActivity` с action
  `es.antonborri.home_widget.action.LAUNCH` и data `habittracker://today`;
  `AppShell` слушает `HomeWidget.widgetClicked` и возвращает на «Сегодня».
- Dart-контракт расширен: `widget_date`, `widget_state`, `widget_items_json`,
  `widget_top_name`, `widget_top_streak` (4 старых ключа сохранены).
- `clearAll()` теперь вызывает `_pushWidget()`; `resumed` обновляет виджет на
  случай смены даты.

### 1.3. Версия (QA-18-03)

- `pubspec.yaml`: `1.0.0+1` → `1.1.0+2`.
- `lib/app/app_info.dart`: `1.0.0` → `1.1.0`.

### 1.4. Приёмка дизайна (D-01…D-05, D-08)

- **D-01:** из шапки карточки напоминания убрана сводка справа; вторая строка
  показывает режим («Один раз в день · 08:00», «Каждые 2 ч · 08:00–22:00»,
  «В дни по расписанию»), справа только `Switch`.
- **D-02:** `ChoiceChip` заменены на сегментированный контрол
  (`surfaceSubtle`, радиус 12, min-height 44, активный сегмент на `surface`).
- **D-03:** «По расписанию каждой привычки».
- **D-04:** «Одно на весь список».
- **D-05:** «Если остались невыполненные».
- **D-08:** `DropdownButton` — `isExpanded` + `selectedItemBuilder`, ширина
  ограничена 140 dp.
- `design/tools/design_review_test.dart` — 6/6 при 320×640, включая
  textScale 1.0/1.3/2.0; overflow отсутствует.

### 1.5. Дополнительно (P2)

- **QA-18-07:** `ReminderPlan.effectiveEvening` выключает сегодняшний вечерний
  слот, если все привычки на сегодня выполнены (или привычек нет). Остальные
  дни недели сохраняют расписание. Пересчёт выполняется после отметки.
- **QA-18-05:** `ReminderPlan.capToLimit` сортирует pending-напоминания по
  времени и оставляет 400 ближайших; дальние не планируются. Применяется в
  `FlutterLocalReminderScheduler.syncAll`.

## 2. Проверки

| Проверка | Результат |
| --- | --- |
| `flutter test` | **118 passed** |
| `flutter test design/tools/design_review_test.dart` | **6 passed** |
| `scripts/analyze.ps1` (ASCII-зеркало) | **No issues found!** |
| `scripts/build_release_apk.ps1` | успешно, split ARM, подпись компании |
| `aapt2 dump badging` | `versionName='1.1.0'`, versionCode `2002` / `1002` |
| Manifest APK | `HabitWidgetProvider`, `APPWIDGET_UPDATE`, meta-data провайдера |
| Ресурсы APK | `layout/widget_habit_2x1`, `widget_habit_4x2`, `widget_habit_row`, `xml/habit_widget_info` |
| DEX APK | класс `Lcom/sukhanovlabs/habittracker/HabitWidgetProvider;` присутствует |

## 3. Артефакты

```
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
  SHA-256 52562F4D35F915AA674A5D793C16CE1124EB80A635F550BCDF2550DF3DED9E75
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
  SHA-256 6D2EA4C9631CFDB48C6FB3FEFAB18D115D2DEABA5BCE9AF8A6EC382DFDD95E60
```

Команда сборки:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
```

## 4. Решения

- **Формат backup** — плоский JSON с `format` + `schemaVersion`; неизвестная
  версия отклоняется, а не «угадывается». История — массив `yyyy-MM-dd`,
  `createdAt` — ISO-8601 UTC, при импорте приводится к локальному времени.
- **Импорт атомарен на уровне валидации:** сначала полностью разбирается файл,
  только затем показывается подтверждение и заменяются данные. Ошибка
  чтения/схемы не трогает Hive.
- **Виджет не пишет данные:** только читает снимок из `HomeWidgetPreferences`.
  Ошибка рендера оставляет последний валидный снимок, а не нули.
- **`stale` вычисляется нативно** по `widget_date != today`, поэтому вчерашние
  «4 из 4» не показываются как сегодняшние.
- **Лимит уведомлений** — 400 ближайших слотов; это защита от тихого отказа
  OEM-планировщиков, а не продуктовая настройка.

## 5. Известные ограничения

1. **Нет устройства/эмулятора:** фактическое добавление виджета на рабочий
   стол, поведение лаунчера, TalkBack, смена темы и доставка уведомлений не
   наблюдались. Проверка виджета — по коду, ресурсам и содержимому release APK.
2. **Виджет 4×2, состояние «серия»** показывает список привычек и серию в
   заголовке/футере; отдельная композиция с крупным пламенем 48 dp из макета
   не реализована (fallback первого релиза по спецификации §3.2/§9.1).
3. **Импорт при отказе хранилища** (не при битом файле) уже мог очистить Hive;
   откат предыдущего списка не реализован. Штатный путь Hive ошибок не даёт.
4. **2×1 при системном шрифте 1.3** может подрезать нижнюю полосу прогресса:
   спецификация запрещает `autoSizeText`, а высота ячейки задаётся лаунчером.
5. **`home_widget` 0.10.0** применяет Kotlin Gradle Plugin — Flutter выдаёт
   предупреждение о будущем переходе на Built-in Kotlin; на сборку 1.1 не влияет.
6. **Share sheet и file picker** в рантайме не проверялись (нет устройства);
   используются штатные API `share_plus 13.3.1` и `file_picker 13.3.2`.
