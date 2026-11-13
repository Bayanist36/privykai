# Отчёт SUK-27: патч 1.1.1

Дата: 3 ноября 2026.
Сборка: `1.1.1+3`, release APK только ARM (arm64-v8a и armeabi-v7a).
Статус: код, тесты, `analyze` и release-сборка готовы; APK в RuStore **не
загружался**, тексты карточки не менялись.

## Что изменено

### QA-24-01 — вечернее напоминание при всех выполненных

Причина подтверждена по исходникам `flutter_local_notifications` 22.3.2:
при `matchDateTimeComponents: dayOfWeekAndTime` плагин при первичной
постановке пересчитывает дату от «сейчас» и сравнивает только день недели и
время. Поэтому перенос даты на следующую неделю игнорировался и слот
сегодняшнего дня всё равно попадал в AlarmManager.

Решение:

- `PlannedReminder` получил флаг `repeatsWeekly`;
- при `EveningReminder.skipToday = true` сегодняшний слот в
  `ReminderPlan.eveningPlan` остаётся на своей дате следующей недели, но
  помечается `repeatsWeekly: false`;
- `FlutterLocalReminderScheduler` для такого слота передаёт
  `matchDateTimeComponents: null`, то есть ставит одноразовый alarm на
  следующую неделю, а не еженедельный, который сработал бы сегодня;
- остальные шесть дней недели по-прежнему еженедельные.

При следующем открытии приложения или любой отметке `syncAll` пересобирает
план: если сегодня ещё есть невыполненные привычки, сегодняшний слот снова
становится еженедельным и приходит в обычное время. Сценарий «есть
невыполненные — напоминание приходит» не изменён.

Тесты: `test/features/reminders/domain/reminder_plan_test.dart` —
сегодняшний слот одноразовый, остальные шесть еженедельные; при прошедшем
времени и при выключенном `skipToday` все слоты еженедельные.

### QA-24-02 — «2 привычек» вместо «2 привычки»

- Диалог импорта и снекбар после импорта используют существующий
  `RussianPlural.habits` (`lib/core/utils/russian_plural.dart`).
- В виджете числительное с существительным не выводится: там формат
  «N из M» / «Осталось N», поэтому правка относится к единственному месту с
  ошибочной формой — диалогу импорта из QA-отчёта.
- Добавлен `test/core/utils/russian_plural_test.dart` для 1/2/5/11/21,
  дополнительно 0/12/14/22/25.

### QA-24-03 — лишние разрешения и Glance/WorkManager

`home_widget` 0.10.0 приносил `androidx.glance:glance-appwidget` и
`androidx.work:work-runtime-ktx`, а вместе с ними `WAKE_LOCK`,
`ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE` и компоненты WorkManager.
WorkManager нужен только для `registerBackgroundCallback` и фоновых
обновлений, которые приложение не использует: виджет обновляется из Flutter
и по системным broadcast'ам (`DATE_CHANGED`, `TIME_SET`, `TIMEZONE_CHANGED`,
`BOOT_COMPLETED`), а `updatePeriodMillis` равен 0.

Поэтому зависимость `home_widget` удалена, вместо неё:

- `lib/features/widget/data/widget_channel.dart` —
  `MethodChannel('com.sukhanovlabs.habittracker/widget')`;
- `HomeWidgetBridgeImpl` пишет те же ключи в те же
  `HomeWidgetPreferences` (совместимо с уже добавленными виджетами);
- `MainActivity` принимает снимок, сохраняет его и отправляет
  `ACTION_APPWIDGET_UPDATE` провайдеру `HabitWidgetProvider`;
- тап по виджету по-прежнему открывает «Сегодня»: холодный старт
  открывается на вкладке «Сегодня», а для уже запущенного приложения
  `MainActivity.onNewIntent` шлёт `widgetTap` в Dart.

Разрешения в release APK после патча:

| Разрешение | Статус | Почему |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | оставлено | напоминания |
| `RECEIVE_BOOT_COMPLETED` | оставлено | восстановление расписания напоминаний после ребута |
| `VIBRATE` | оставлено | вибрация уведомлений (`flutter_local_notifications`) |
| `INTERNET` | отсутствует | приложение офлайн |
| `ACCESS_NETWORK_STATE` | удалено | было только у WorkManager |
| `FOREGROUND_SERVICE` | удалено | было только у WorkManager |
| `WAKE_LOCK` | удалено | было только у WorkManager; `RTC_WAKEUP` alarm'ам разрешение не нужно |

`androidx.work` и `androidx.glance` отсутствуют в DEX release APK (проверено
поиском по `classes*.dex`). `androidx.startup.InitializationProvider`
остался от `androidx.profileinstaller` и к WorkManager не относится.

### Версия

- `pubspec.yaml`: `1.1.1+3`;
- `AppInfo.version`: `1.1.1`.

## Проверки

| Команда | Результат |
| --- | --- |
| `flutter pub get` | зависимости разрешены, `home_widget` удалён |
| `flutter test` | **121 тест, все прошли** |
| `scripts/analyze.ps1` | `No issues found!` (ASCII-зеркало) |
| `scripts/build_release_apk.ps1` | оба ARM APK собраны и подписаны ключом компании |

`aapt2 dump badging` для `app-arm64-v8a-release.apk`:

- `versionName='1.1.1'`;
- `versionCode='2003'` (arm64), выше опубликованного 2002 у 1.1.0;
- `minSdkVersion='24'`, `targetSdkVersion='36'`;
- label `Привыкай`;
- `native-code: 'arm64-v8a'`.

`aapt2 dump badging` для `app-armeabi-v7a-release.apk`: `versionCode='1003'`,
`versionName='1.1.1'`, `native-code: 'armeabi-v7a'`.

`apksigner verify` — подпись компании
`CN=Sukhanov labs, O=Sukhanov labs, C=RU`.

## Артефакты

| Файл | ABI | Размер | SHA-256 |
| --- | --- | --- | --- |
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | arm64-v8a | 19 565 750 Б (18,7 МБ) | `D4AAF4072E40A33D494712D71E5E51241EF5633BDD11E0E57AAF4D10B43D3DDD` |
| `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` | armeabi-v7a | 17 187 456 Б (16,4 МБ) | `AB6EA6DFD54877F2580DD7254B155A19A7CA6943D6F68AC2D6E72F8C7BEF7178` |

APK приложены к задаче SUK-27. В RuStore ничего не загружалось.

## Ограничения

- Устройство/эмулятор в этом прогоне не подключались: фактическая доставка
  вечернего уведомления в 20:00 и отсутствие сегодняшнего alarm'а проверены
  на уровне плана и по коду плагина; ручной smoke на Android 13+ остаётся
  recommended перед загрузкой.
- Одноразовый слот «следующая неделя» живёт до ближайшей синхронизации
  напоминаний (открытие приложения или отметка привычки), после чего снова
  становится еженедельным. Это осознанный компромисс: без нативного
  периодического receiver нельзя одновременно пропустить только сегодняшний
  слот и сохранить еженедельный повтор у плагина с багом из QA-24-01.
- Тексты карточки RuStore не менялись, версия 1.1 остаётся на модерации.
