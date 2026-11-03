# SUK-13. Исправление блокеров QA и release candidate

**Дата:** 23 октября 2026
**Автор:** Flutter-разработчик
**Источник:** отчёт QA SUK-11 (`qa-report`, вердикт «не публиковать»)
**Статус:** блокеры BUG-01, BUG-02 и BUG-03 закрыты в коде; release
candidate собран. Подпись компании ждёт решения владельца.

## 1. Итог

- `scripts/verify.ps1`: **84 теста зелёные**, `flutter analyze` — `No issues
  found!`, debug APK собирается.
- Release APK: **два split-APK** под ARM, 16,1 МБ и 18,4 МБ (было 52,7 МБ
  universal). Оба содержат `ic_notification`, adaptive icon, русский label
  «Привыкай» и receivers напоминаний.
- `scripts/verify_release_apk.ps1`: проверяет `apksigner`, label, adaptive icon,
  `ic_notification`, permissions и manifest напоминаний. Обе сборки проходят.
- Release всё ещё подписан **debug-ключом**: `android/key.properties` и
  keystore не создавались по прямому указанию задачи (ждём владельца).
  Скрипт генерации и конфигурация подписи готовы.

## 2. Блокеры

### BUG-01/BUG-04 — typeId Hive и чтение после переоткрытия

Причин было две, обе воспроизводятся только после `close()` + повторного
`openBox()`:

1. **Зарезервированные typeId.** `HabitAdapter` использовал 0, а
   `AppSettingsAdapter` — 1. Hive резервирует 0–12 под встроенные
   `FrameValueType`. Адаптеры переведены на **13 (привычки)** и **14
   (настройки)**.
2. **Ошибка в `read`.** Счётчик полей читался прямо в условии цикла:
   `for (var i = 0; i < reader.readByte(); i++)`. Условие выполняется перед
   каждой итерацией, поэтому байт счётчика съедался повторно, и карта полей
   оставалась пустой (`fields[0] == null`). Счётчик теперь читается один раз
   в локальную переменную в обоих адаптерах.

Регрессия:

- `habit survives close and a second openBox` — запись → `close()` →
  повторный `openBox()` → чтение всех полей привычки.
- `settings survive close and a second openBox` — то же для темы,
  напоминаний, времени и флага онбординга.
- `Hive adapter typeIds stay outside the reserved 0-12 range` — тест-страж:
  typeId ≥ 13, уникальны и закреплены как 13/14.

**Совместимость:** публичных релизов не было, поэтому данные dev-сборок с
typeId 0/1 не мигрируются. Для проверки RC нужен чистый первый запуск
(удалить приложение или очистить данные). Это остаточный риск для тестовых
устройств, но не для пользователей RuStore.

### BUG-02 — `ic_notification` в release и ошибка инициализации

- Добавлен `android/app/src/main/res/raw/keep.xml` с
  `tools:keep="@drawable/ic_notification"`: ресурс больше не вырезается
  шринкером.
- `FlutterLocalReminderScheduler.initialize` оборачивает инициализацию плагина
  в `try/catch`, логирует ошибку и пробрасывает её вызывающему.
- Форма привычки перехватывает ошибку `areNotificationsEnabled` /
  `requestPermission`: переключатель остаётся выключенным, показывается
  снекбар «Не удалось включить напоминание. Попробуйте ещё раз.», приложение
  не падает.
- Добавлен виджет-тест с планировщиком, который падает на инициализации.

### BUG-03 — release-подпись

- `android/app/build.gradle.kts` читает `android/key.properties` и создаёт
  `signingConfigs.release`; при отсутствии файла используется debug-ключ с
  предупреждением в логе (нужно для QA-сборки).
- `android/key.properties.example` — шаблон без секретов.
- `.gitignore`: `/android/key.properties`, `*.jks`, `*.keystore`.
- `scripts/generate_release_keystore.ps1` — генерация RSA-4096 keystore вне
  репозитория, запись `key.properties`, напоминание о бэкапе. **Не запускался**
  по указанию задачи.
- `scripts/verify_release_apk.ps1` — `apksigner verify --print-certs`; debug
  подпись отклоняется, если не передан `-AllowDebugSignature` (используется
  только для текущего QA-артефакта).

## 3. Остальные дефекты

| ID | Что сделано |
| --- | --- |
| BUG-05 | Снекбар «Выполнено. Серия: N» с «Отменить» на 5 секунд; повторный тап показывает «Отметка снята». `HabitListController.toggleCompletion` возвращает сохранённую привычку, undo перечитывает актуальное состояние. Покрыто widget-тестами. |
| BUG-06 | `LocalTimeZone`: сначала IANA-идентификатор, затем алиасы (`GMT` → `Etc/GMT`, `UTC` → `Etc/UTC`), затем фиксированное смещение устройства (`UTC+03:00`, включая 30/45 минут). Молчаливого UTC больше нет. 5 unit-тестов. |
| BUG-07 | Текст политики обновлён: разрешение нужно для локальных напоминаний, уведомления не покидают устройство. |
| BUG-08 | Встроенный экран политики сохранён; публичный URL вынесен в `AppInfo.privacyPolicyUrl` (пустой до SUK-15). Сеть и `INTERNET` не добавлялись. |
| BUG-09 | Варианты темы обёрнуты в `Semantics(selected:)`; TalkBack сообщает выбранный вариант. Widget-тест проверяет флаг `isSelected`. |
| BUG-10 | `scripts/build_release_apk.ps1` собирает `--split-per-abi` только под `android-arm` и `android-arm64`. Размеры 16,1 и 18,4 МБ. |
| BUG-11 | `android:label`, `AppInfo.name` и `MaterialApp.title` — «Привыкай». Adaptive icon (`mipmap-anydpi-v26` + foreground + monochrome) уже был из SUK-10; release-проверка подтверждает его наличие. |

## 4. Release-артефакты

Сборка: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1`.

| Файл | ABI | Размер | versionCode | Подпись |
| --- | --- | --- | --- | --- |
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | arm64-v8a | 18,4 МБ | 2001 | debug (ждёт ключ) |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | armeabi-v7a | 16,1 МБ | 1001 | debug (ждёт ключ) |

Обе сборки:

- `applicationId` `com.sukhanovlabs.habittracker`, versionName `1.0.0`;
- `application-label:'Привыкай'`;
- `drawable/ic_notification` и adaptive icon присутствуют;
- `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
  `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` есть;
- `INTERNET` отсутствует.

Проверка: `pwsh -NoProfile -ExecutionPolicy Bypass -File
scripts/verify_release_apk.ps1 -AllowDebugSignature` (флаг нужен только пока
нет ключа компании).

## 5. Изменённые файлы

- `lib/features/habits/data/models/habit_adapter.dart`
- `lib/features/settings/data/models/app_settings_adapter.dart`
- `lib/features/reminders/domain/local_time_zone.dart` (новый)
- `lib/features/reminders/data/flutter_local_reminder_scheduler.dart`
- `lib/features/habits/presentation/controllers/habit_list_controller.dart`
- `lib/features/habits/presentation/screens/habits_screen.dart`
- `lib/features/habits/presentation/screens/habit_form_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `lib/features/settings/presentation/screens/privacy_policy_screen.dart`
- `lib/app/app_info.dart`, `lib/app/app.dart`
- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/raw/keep.xml` (новый)
- `android/key.properties.example`, `.gitignore`
- `scripts/generate_release_keystore.ps1`, `scripts/build_release_apk.ps1`,
  `scripts/verify_release_apk.ps1`
- тесты: `test/core/storage/adapter_type_id_test.dart`,
  `test/features/habits/data/habit_hive_integration_test.dart`,
  `test/features/reminders/domain/local_time_zone_test.dart`,
  `test/widget_test.dart`, `test/support/throwing_reminder_scheduler.dart`

## 6. Остаточные риски

1. **Release-ключ не создан.** Артефакты подписаны debug-ключом и не готовы к
   загрузке в RuStore. Нужен keystore владельца, после чего повторить
   `scripts/build_release_apk.ps1` без `-AllowDebugSignature`.
2. **Нет устройства/эмулятора.** Реальный smoke напоминаний на release APK
   (доставка, тап, ребут, смена TZ) не выполнен. Статическая проверка
   артефакта пройдена; нужен ручной прогон на Android 13+.
3. **Матрица устройств не покрыта** (API 26/34, OEM). Риск энергосбережения
   и inexact-будильников сохраняется.
4. **Старые dev-данные несовместимы** из-за смены typeId. Публичных
   пользователей нет; перед проверкой RC нужен чистый запуск.
5. **Политика URL** пуста до SUK-15; встроенный экран работает офлайн.
6. **Точность напоминаний** — `inexactAllowWhileIdle` (±15 минут) по брифу.
   Текст онбординга «Напоминания вовремя» остаётся продуктовым компромиссом.
7. **Inter не встроен** (в дизайн-пакете только WOFF2), используется Roboto.
8. X86_64 APK не собирается намеренно: RuStore-ассортимент — ARM. Для
   эмулятора нужна отдельная debug-сборка.

## 7. Решение для руководителя

Нужно решение по release-ключу: сгенерировать `scripts/generate_release_keystore.ps1`
(ключ и пароли хранятся вне git) и пересобрать RC. После этого — ручной smoke
на устройстве и повторный QA-прогон SUK-11.
