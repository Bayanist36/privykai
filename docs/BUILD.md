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
| `app-arm64-v8a-release.apk` | arm64-v8a | 18,4 МБ | 2001 |
| `app-armeabi-v7a-release.apk` | armeabi-v7a | 16,1 МБ | 1001 |

Проверено для обеих сборок:

- `applicationId` `com.sukhanovlabs.habittracker`, versionName `1.0.0`;
- `application-label:'Привыкай'`;
- `drawable/ic_notification` присутствует (BUG-02);
- adaptive launcher icon (`mipmap-anydpi-v26`) присутствует;
- `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`,
  `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` есть;
- `INTERNET` отсутствует;
- `apksigner verify` проходит.

**Подпись:** сертификат `C=US, O=Android, CN=Android Debug`. Keystore
компании не создавался по решению задачи; конфигурация и скрипт готовы. Для
публикации нужен `android/key.properties` и пересборка без
`-AllowDebugSignature`.

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

Ожидаемый результат: 84 теста зелёные, анализ без замечаний, debug APK и два
ARM release APK в `build\app\outputs\flutter-apk\`, release-проверка зелёная
(с `-AllowDebugSignature`, пока нет ключа компании).

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
