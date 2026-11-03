# Привыкай (habit_tracker)

Офлайн-трекер привычек для Android от Sukhanov labs. Первая площадка — RuStore,
затем Google Play. Без бэкенда, аккаунтов и платежей в MVP: все данные хранятся
на устройстве.

Сейчас в приложении работает:

- Flutter-проект с Android-таргетом и стабильным application ID
  `com.sukhanovlabs.habittracker`;
- feature-first структуру с разделением domain/data/presentation;
- тему Material 3 на токенах дизайн-системы из `design/` и переключение
  «Системная / Светлая / Тёмная» с сохранением выбора;
- локальное хранилище Hive: привычки (typeId 13) и настройки (typeId 14);
- «Сегодня»: только привычки по расписанию, прогресс дня, серии, пояснение
  для привычек на другие дни;
- создание и редактирование привычки: название, эмодзи, цвет, дни недели,
  время напоминания; отметка со снекбаром «Выполнено. Серия: N» и отменой
  в течение 5 секунд; удаление с подтверждением;
- расписание по дням недели с режимом «Каждый день» и серии по
  запланированным дням;
- локальные напоминания: время на привычку, одно уведомление на выбранный
  день недели, восстановление расписания после перезагрузки, разрешение
  Android 13+ с объяснением и обработкой отказа;
- экран статистики: сводка за 7 дней, проценты за 30 дней, текущая и лучшая
  серия по каждой привычке, пустые состояния по SUK-4;
- онбординг первого запуска (3 слайда) и пустое состояние по макетам SUK-4;
- настройки: тема, глобальный переключатель напоминаний, время по умолчанию,
  сброс данных с двумя диалогами, «О приложении» и локальная политика
  конфиденциальности;
- миграцию данных SUK-5 без потери отметок: новые поля имеют безопасные
  значения по умолчанию;
- unit- и widget-тесты, скрипты сборки и проверки.

## Версии инструментов

Проверено 23 октября 2026 года.

| Компонент | Версия |
| --- | --- |
| Flutter (stable) | 3.47.7, revision `abaf9c5237` |
| Dart | 3.13.5 |
| Java (JDK) | 19.0.2 (Microsoft/OpenJDK, `C:\Program Files\Java\jdk-19`) |
| Gradle (wrapper) | 9.3.1 |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
| Android SDK Platform | 36 |
| Android Build-Tools | 36.0.0 |
| Android Platform-Tools | 37.0.1 |
| Android NDK | 28.2.13676358 |
| compileSdk / targetSdk / minSdk | 36 / 36 / 24 |
| provider | 6.1.5+1 |
| hive / hive_flutter | 2.2.3 / 1.1.0 |
| intl | 0.20.3 |
| uuid | 4.6.0 |
| flutter_local_notifications | 22.3.2 (локальные напоминания) |
| timezone / flutter_timezone | 0.11.2 / 5.1.1 (часовой пояс планировщика) |

Flutter SDK и Android SDK на текущей машине установлены на диск `D:` из-за
нехватки места на `C:`:

- Flutter: `D:\dev\flutter`
- Android SDK: `D:\dev\android-sdk`
- Gradle user home: `D:\dev\gradle-home` (кэш Gradle, иначе `C:` переполняется)

Пути к SDK не коммитятся: `android/local.properties` генерируется Flutter и
указан в `.gitignore`. На другой машине достаточно выполнить
`flutter config --android-sdk <path>` и `flutter pub get`.

## Быстрый старт

Требуются Flutter 3.47.x, Android SDK 36 с build-tools 36.0.0 и JDK 17+.
Команды выполняются из корня проекта.

```powershell
flutter pub get
flutter run                 # запуск на подключённом устройстве/эмуляторе
flutter test                # 84 теста
dart analyze                # работает в текущем не-ASCII пути
```

`flutter analyze` в этом рабочем пространстве падает внутри analysis server
(см. «Известные ограничения»), поэтому для точного воспроизведения проверки
используйте скрипт:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/analyze.ps1
```

Скрипт при необходимости копирует проект в ASCII-путь
`C:\Users\Public\habit_tracker_verify` и запускает `flutter analyze` там.

## Сборка debug APK

```powershell
flutter build apk --debug
```

или скрипт, который сам находит Flutter, Android SDK и JDK:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_debug_apk.ps1
```

Артефакт: `build\app\outputs\flutter-apk\app-debug.apk`.

Полная проверка (pub get, тесты, анализ, debug-сборка):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/verify.ps1
```

## Сборка release для RuStore

Для подписи создайте ключ компании (один раз, храните keystore и пароли вне
git и сделайте резервную копию):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/generate_release_keystore.ps1
```

Скрипт создаёт keystore в `%USERPROFILE%\.sukhanovlabs` и
`android/key.properties` (в git не попадает). Без этого файла release
собирается с debug-ключом и предупреждением — только для QA, не для RuStore.

Сборка двух ARM APK и проверка артефакта:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/build_release_apk.ps1
```

Артефакты: `app-arm64-v8a-release.apk` и `app-armeabi-v7a-release.apk` в
`build\app\outputs\flutter-apk\`. Скрипт проверяет `apksigner`, label,
`ic_notification`, adaptive icon, permissions и manifest напоминаний. Пока
`android/key.properties` нет, для QA используйте
`scripts/verify_release_apk.ps1 -AllowDebugSignature`.

Подробности RC — `docs/REPORT_SUK-13.md`; окружение и история сборок —
`docs/BUILD.md`.

Переменные окружения, если они не настроены глобально:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-19'
$env:ANDROID_HOME = 'D:\dev\android-sdk'
$env:ANDROID_SDK_ROOT = 'D:\dev\android-sdk'
$env:GRADLE_USER_HOME = 'D:\dev\gradle-home'
$env:Path = "D:\dev\flutter\bin;$env:Path"
```

## Установка тулчейна с нуля

1. Скачать Flutter stable с https://docs.flutter.dev/release/archive,
   распаковать, например, в `D:\dev\flutter`, добавить `D:\dev\flutter\bin`
   в `PATH`.
2. Установить JDK 17 или 21, задать `JAVA_HOME`.
3. Установить Android command-line tools и пакеты:

   ```powershell
   sdkmanager --sdk_root=D:\dev\android-sdk --licenses
   sdkmanager --sdk_root=D:\dev\android-sdk "platform-tools" "platforms;android-36" "build-tools;36.0.0"
   ```

4. Указать пути Flutter:

   ```powershell
   flutter config --android-sdk D:\dev\android-sdk
   flutter config --jdk-dir "C:\Program Files\Java\jdk-19"
   flutter doctor -v
   ```

5. Выполнить `flutter pub get` и `flutter build apk --debug`.

## Структура проекта

```text
lib/
  main.dart                         # Hive, локаль, репозитории, запуск
  app/
    app.dart                        # MaterialApp, тема, Provider, онбординг
    app_shell.dart                  # вкладки «Сегодня / Статистика / Настройки»
    app_palette.dart                # светлая/тёмная палитра (ThemeExtension)
    app_info.dart                   # название, версия, копирайт
    theme/                          # цвета, отступы, Material 3 тема
  core/
    storage/hive_storage.dart       # привычки + настройки, адаптеры
    utils/weekdays.dart             # битовая маска дней недели
    utils/date_key.dart             # ключи дат yyyy-MM-dd
    utils/russian_plural.dart
  features/habits/
    domain/models/habit.dart        # расписание, серии, отметки
    data/models/habit_adapter.dart  # ручной Hive TypeAdapter (typeId 13)
    presentation/
      controllers/habit_list_controller.dart
      screens/habits_screen.dart    # «Сегодня»
      screens/habit_form_screen.dart # создание/редактирование
      widgets/                      # прогресс, карточка, пустые состояния
      constants/                    # эмодзи и цвета привычек
  features/onboarding/              # 3 слайда первого запуска
  features/settings/                # модель, Hive, контроллер, экран
  features/reminders/
    domain/reminder_plan.dart       # дни, id и время уведомлений (чистые функции)
    domain/reminder_scheduler.dart  # интерфейс + no-op для тестов
    data/                           # flutter_local_notifications + timezone
  features/statistics/
    domain/habit_statistics.dart    # сводка 7 дней, 30 дней, серии
    presentation/                   # экран и карточки статистики
test/                               # unit- и widget-тесты
design/                             # макеты и токены от дизайнера
scripts/                            # сборка, анализ, полная проверка
```

Подробные решения и схема хранения — в `docs/ARCHITECTURE.md`.

## Хранилище и миграция

Hive, box `habits`, один документ на привычку. Поля: `id`, `name`, `iconKey`,
`colorKey`, `weekdaysMask`, `reminderMinutes`, `createdAt`, `completedDates`.
Даты выполнения хранятся строками `yyyy-MM-dd`, поэтому отметка не зависит от
времени суток и часового пояса.

`weekdaysMask` — битовая маска, Пн = `1 << 0` … Вс = `1 << 6`, «каждый день» =
`0x7F`. Второй box `settings` хранит один документ `app`: режим темы,
глобальный переключатель напоминаний, время по умолчанию и флаг онбординга.

Адаптеры написаны вручную (typeId **13** для привычек и **14** для настроек),
кодогенерация не нужна. Диапазон 0–12 в Hive зарезервирован под встроенные
типы, поэтому адаптер там читался как встроенный и терял поля (BUG-01/BUG-04).
Счётчик полей при чтении берётся один раз — иначе повторное чтение в условии
цикла съедало байты и карта полей оставалась пустой после переоткрытия бокса.

Документы SUK-5 содержали только первые 6 полей привычки; при чтении
отсутствующие `colorKey` и `weekdaysMask` получают `green` и «каждый день», а
`completedDates` и время напоминания сохраняются. Пользователи с существующими
привычками не видят онбординг при обновлении.

Данные dev-сборок до RC (typeId 0/1) несовместимы с новой схемой: публичных
релизов не было, поэтому миграция не делалась. Перед проверкой RC удалите
приложение или очистите его данные.

## Известные ограничения

- **Не-ASCII путь рабочего пространства.** Текущий путь содержит `Владимир`.
  AGP требует `android.overridePathCheck=true` (уже добавлено в
  `android/gradle.properties`), иначе сборка падает. `flutter analyze` в
  Flutter 3.47.7 не запускает analysis server на таком пути: в LSP-сообщении
  `Content-Length` считается не в байтах, JSON обрезается
  (`FormatException: Unexpected end of input`). Обход: `dart analyze` или
  `scripts/analyze.ps1` с ASCII-зеркалом. На пути без кириллицы
  `flutter analyze` работает штатно.
- **JDK 19.** Сборка проверена на JDK 19.0.2, но для CI рекомендуется LTS
  JDK 17 или 21.
- **Release-подпись.** Конфигурация, скрипт генерации ключа и проверка
  `apksigner` готовы, но сам keystore компании ещё не создан: решение
  владельца. До этого release APK подписан debug-ключом и не публикуется.
  После создания `android/key.properties` пересоберите RC.
- **Напоминания.** Планируются `flutter_local_notifications` в режиме
  `inexactAllowWhileIdle` (±15 минут), без `SCHEDULE_EXACT_ALARM`: точность
  зависит от системного планировщика и режима энергосбережения. На некоторых
  прошивках (Xiaomi, Huawei и др.) система может ограничивать фоновые
  уведомления — это ограничение ОС, а не приложения.
- **Проверка уведомлений.** В окружении нет устройства/эмулятора Android,
  поэтому фактическое появление уведомления и восстановление после перезагрузки
  проверены только unit-тестами планировщика, merged-манифестом и статической
  проверкой release APK (`ic_notification`, receivers, permissions). Ручной
  smoke-тест нужен на устройстве/эмуляторе.
- **Часовой пояс.** `LocalTimeZone` разбирает IANA-идентификаторы и алиасы
  `GMT`/`UTC`, а для неизвестных зон использует текущее смещение устройства.
  Молчаливого UTC больше нет; смена пояса подхватывается при возврате в
  приложение и после перезагрузки.
- **Статистика.** Сводка 7 дней и проценты за 30 дней считаются по
  запланированным дням; сегодняшний невыполненный слот входит в знаменатель.
  Лучшая серия пересчитывается по истории при каждом открытии экрана.
- **Онбординг и бриф.** SUK-3/SUK-4 описывают первый запуск без онбординга, а
  SUK-8 требует три слайда по макетам `01*`. Реализованы слайды; расхождение
  зафиксировано в отчёте задачи и требует подтверждения продукта.
- **Политика конфиденциальности.** Открывается локальный текст с актуальным
  описанием напоминаний. Публичный URL для карточки RuStore вынесен в
  `AppInfo.privacyPolicyUrl` и будет заполнен маркетингом в SUK-15.
- **Ручной smoke-тест.** В окружении нет устройства/эмулятора, поэтому APK не
  устанавливался. Сценарии покрыты widget-тестами и проверены статически.
- **Шрифт Inter.** Дизайн-система поставляет Inter в `.woff2`, Flutter требует
  `.ttf`/`.otf`. Пока используется системный Roboto; нужно передать TTF или
  подключить пакет шрифтов.
- **Иконка приложения.** Лаунчер-иконка из SUK-10 внедрена: legacy
  `mipmap-*`, adaptive `mipmap-anydpi-v26/ic_launcher.xml` с foreground и
  monochrome. Наличие проверяется в release APK.
- **Название.** Утверждённое имя — «Привыкай»; оно задано в `android:label`,
  `AppInfo.name` и `MaterialApp.title`.
- **Только Android.** Платформы iOS/web/desktop не генерировались.
- **Шифрование.** Hive-box не шифруется; резервное копирование и правила
  `allowBackup` не настраивались. Для привычек это допустимо, секретов в
  приложении нет.
- **Debug-сборка не для распространения.** Debug APK — около 151 МиБ (все
  ABI, debug-символы) и содержит `INTERNET` из debug-манифеста Flutter для
  hot reload. Release-манифест этого разрешения не содержит.
- **Release-сборка — только ARM.** `build_release_apk.ps1` собирает
  `--split-per-abi` под `armeabi-v7a` и `arm64-v8a`; x86_64 не входит в
  RuStore-артефакт. Для эмулятора используйте debug-сборку.
- **Токены дизайна.** `design-system.css` ссылается на
  `design/tokens/design-tokens.json`, но файла пока нет; значения перенесены
  из CSS вручную.
- **CI.** Пайплайна нет; `scripts/verify.ps1` — основа для будущего CI.

## Что проверено

- `flutter test` — 84 теста, все проходят (включая переоткрытие Hive-боксов,
  страж typeId, расписание, онбординг, настройки, планировщик напоминаний,
  фолбэк часового пояса, статистику и снекбар с отменой).
- `flutter analyze` на ASCII-зеркале — `No issues found!`.
- `flutter build apk --debug` — APK собран, путь
  `build\app\outputs\flutter-apk\app-debug.apk`.
- `scripts/build_release_apk.ps1` — два ARM release APK (16,1 и 18,4 МБ),
  проверены `apksigner`, label «Привыкай», `ic_notification`, adaptive icon,
  permissions и manifest напоминаний. Подпись пока debug — ждёт ключ компании.

Подробный отчёт RC, список фиксов и остаточных рисков —
`docs/REPORT_SUK-13.md`; окружение и история сборок — `docs/BUILD.md`;
решения SUK-9 — `docs/REPORT_SUK-9.md`; история SUK-8 — в разделе
архитектуры.

## Продуктовый скоуп

Источник: SUK-3, SUK-4, SUK-8 и SUK-9. Продуктовые решения не меняются без
аналитика и руководителя. Замечания по UX и новые фичи — через аналитика.
