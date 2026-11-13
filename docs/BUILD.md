# Отчёт о сборке

Дата проверки: 23 октября 2026, вечер (MSK).
Задача: SUK-13 «Исправить блокеры QA и подготовить RC».
Предыдущая проверка SUK-9 сохранена в истории git; отчёт о фиксах QA —
`docs/REPORT_SUK-13.md`.

## Окружение

- Windows 11 (26H2, build 26300.9711), PowerShell 7.
- Flutter 3.47.7 stable, revision `abaf9c5237`, SDK `D:\dev\flutter`.
- Dart 3.13.5.
- JDK 19.0.2 (`C:\Program Files\Java\jdk-19`), `JAVA_HOME` используется
  Gradle.
- Android SDK `D:\dev\android-sdk`:
  - platform-tools 37.0.1;
  - platforms: android-36 (rev 2), дополнительно android-35 (rev 2);
  - build-tools 36.0.0;
  - NDK 28.2.13676358;
  - CMake 3.22.1.
- Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0.
- `GRADLE_USER_HOME=D:\dev\gradle-home` — кэш Gradle вынесен с системного
  диска `C:`.

## Выполненные команды

```powershell
flutter pub get
flutter test
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/analyze.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify_release_apk.ps1 -AllowDebugSignature
```

`scripts/verify.ps1` выполняет pub get, тесты, анализ и debug-сборку одной
командой.

## Результаты

- `flutter test`: **84 теста, все прошли**. Новые тесты:
  - переоткрытие Hive-бокса для привычек и настроек (BUG-01/BUG-04);
  - страж typeId адаптеров (0–12 зарезервированы);
  - часовой пояс: IANA, `GMT`/`UTC`, неизвестная зона, смещение +3 / +5:30 /
    −4;
  - снекбар «Выполнено. Серия» с отменой и «Отметка снята»;
  - ошибка инициализации плагина напоминаний в форме;
  - семантика выбранной темы для TalkBack.
- `flutter analyze` (ASCII-зеркало `C:\Users\Public\habit_tracker_verify`):
  `No issues found!`.
- `flutter build apk --debug`: успешно.

## Release APK (RC)

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
```

Скрипт собирает `--split-per-abi` только под ARM и сразу запускает
`scripts/verify_release_apk.ps1`.

| Файл | ABI | Размер | versionCode |
| --- | --- | --- | --- |
| `app-arm64-v8a-release.apk` | arm64-v8a | 19,6 МБ | 2002 |
| `app-armeabi-v7a-release.apk` | armeabi-v7a | 17,3 МБ | 1002 |

Проверено для обеих сборок:

- `applicationId` `com.sukhanovlabs.habittracker`, versionName `1.1.0`;
- `application-label:'Привыкай'`;
- `drawable/ic_notification` присутствует (BUG-02);
- adaptive launcher icon (`mipmap-anydpi-v26`) присутствует;
- `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
  `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` есть;
- виджет: `HabitWidgetProvider`, `APPWIDGET_UPDATE`, meta-data
  `android.appwidget.provider`, `res/xml/habit_widget_info`, layout 2×1/4×2;
- `INTERNET` отсутствует;
- `apksigner verify` проходит.

**Подпись:** сертификат компании `CN=Sukhanov labs, O=Sukhanov labs, C=RU`
из `android/key.properties`. Для публикации пересборка без
`-AllowDebugSignature` не требуется.

## Сборка и подпись

1. Один раз создать ключ компании (keystore вне репозитория):

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/generate_release_keystore.ps1
   ```

2. Пересобрать RC:

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
   ```

3. Проверить подпись без QA-послабления:

   ```powershell
   pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify_release_apk.ps1
   ```

`android/key.properties`, `*.jks` и `*.keystore` исключены из git.

## Ограничения проверки

- Устройство/эмулятор не подключались: `adb devices` пуст. Реальный smoke
  напоминаний на release APK (доставка, тап по уведомлению, перезагрузка,
  смена часового пояса) не выполнен. Статическая проверка артефакта
  (иконка, receivers, permissions, `apksigner`) пройдена; нужен ручной прогон
  на Android 13+.
- `flutter analyze` запускается через ASCII-зеркало из-за кириллицы в пути
  рабочего пространства (см. README).
- Первая release-сборка столкнулась с таймаутом загрузки
  `desugar_jdk_libs` с `dl.google.com`; Flutter автоматически повторил сборку,
  артефакты собрались. Для CI нужен прогретый Gradle-кэш или зеркало.
- Точность напоминаний зависит от системного планировщика Android и
  энергосбережения производителя; `SCHEDULE_EXACT_ALARM` не запрашивается.
- Данные dev-сборок до RC (typeId 0/1) несовместимы: перед проверкой удалите
  приложение или очистите данные. Публичных релизов не было.

## Повторная проверка

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
```

Ожидаемый результат: 104 теста зелёные (после SUK-17), анализ без замечаний,
debug APK и два ARM release APK в `build\app\outputs\flutter-apk\`,
release-проверка зелёная (с `-AllowDebugSignature`, пока нет ключа компании).

## Как проверить напоминание на устройстве

1. Установить `app-arm64-v8a-release.apk` на Android 13+ (чистая установка).
2. Создать привычку, включить «Напоминание», разрешить уведомления и выбрать
   время на 2–3 минуты вперёд в один из выбранных дней.
3. Дождаться уведомления (допустимо ±15 минут) и проверить, что тап открывает
   «Сегодня».
4. Перезагрузить устройство и убедиться, что расписание сохранилось.
5. Выключить глобальный переключатель в настройках — уведомления не приходят;
   включить — возвращаются.
6. Сменить часовой пояс устройства и вернуться в приложение — время
   напоминания должно оставаться локальным (08:00, а не 11:00).

## Обновление SUK-17 (3 ноября 2026)

Актуальные решения, команды и ограничения — `docs/REPORT_SUK-17.md`.

- Добавлены интервальные напоминания (каждые N часов в окне) и вечернее
  напоминание.
- `flutter test`: 104 теста зелёные; `dart analyze`: без замечаний.
- Debug APK собран и проверен на временном AVD Android 15 (API 35):
  2 ч / 08:00–22:00 даёт 56 alarms на неделю (8 в день), вечернее
  напоминание добавляет 7 и снимается при выключении.
- Release APK/AAB в SUK-17 не пересобирались; перед публикацией повторить
  `scripts/build_release_apk.ps1` и `scripts/verify_release_apk.ps1`.

## Обновление SUK-27 (3 ноября 2026, патч 1.1.1)

Подробности — `docs/REPORT_SUK-27.md`.

- Версия `1.1.1+3` (`pubspec.yaml`, `AppInfo.version` = `1.1.1`).
- QA-24-01: сегодняшний слот вечернего напоминания при всех выполненных
  привычках ставится одноразово на следующую неделю
  (`repeatsWeekly: false`, `matchDateTimeComponents: null`); остальные дни
  остаются еженедельными.
- QA-24-02: диалог и снекбар импорта используют `RussianPlural.habits`;
  тест на 1/2/5/11/21 добавлен.
- QA-24-03: `home_widget` удалён вместе с Glance/WorkManager; снимок виджета
  пишется через `WidgetChannel` в `MainActivity`. В release остались только
  `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`.
- `flutter test` — 121 тест зелёный; `scripts/analyze.ps1` — без замечаний.
- Release: `app-arm64-v8a-release.apk` versionCode 2003 / 18,7 МБ,
  `app-armeabi-v7a-release.apk` versionCode 1003 / 16,4 МБ,
  versionName `1.1.1`, подпись компании. В RuStore не загружались.

## Обновление SUK-28 (13 ноября 2026, патч 1.1.1)

Подробности — `docs/REPORT_SUK-28.md`.

- Экран политики переписан под редакцию 1.1: экспорт/импорт JSON, виджет,
  уведомления на экране блокировки, системный backup Android; абсолютная
  формулировка «данные только на устройстве» убрана.
- `AppInfo.privacyPolicyUrl` = `https://Bayanist36.github.io/privykai-privacy/privykai-privacy.html`;
  добавлен `AppInfo.privacyPolicyEdition = '1.1'`. Ссылка выводится текстом,
  приложение сеть не открывает и не имеет `INTERNET`.
- Версия не менялась: `1.1.1+3`.
- `flutter test` — 125 тестов зелёные (4 новых про экран политики);
  `scripts/analyze.ps1` — без замечаний.
- Release пересобран: arm64-v8a versionCode 2003 / 18,72 МБ,
  armeabi-v7a versionCode 1003 / 16,41 МБ, подпись компании. В RuStore
  не загружались.
