# SUK-9. Напоминания и экран статистики

**Итог:** F5 и F6 реализованы, 72 теста зелёные, `flutter analyze` без
замечаний, debug APK собирается. Отчёт о сборке — `docs/BUILD.md`.

## Проверка после SUK-8

SUK-8 (редактирование, расписание, онбординг, настройки) завершён, поэтому
интеграция проверена повторно в общем рабочем пространстве:

- `scripts/verify.ps1`: 72 теста зелёные, `flutter analyze` — `No issues
  found!`, debug APK собран.
- Проверено, что редактирование привычки и смена расписания пересоздают
  напоминания (`test/features/reminders/presentation/reminder_sync_test.dart`),
  а глобальный выключатель из настроек отменяет и восстанавливает расписание.
- Статистика использует тот же `HabitListController`, что и «Сегодня», поэтому
  правки из SUK-8 сразу видны на экране статистики.
- Удалён неиспользуемый дубль `lib/app/shell/app_shell.dart`; актуальный каркас
  с тремя вкладками — `lib/app/app_shell.dart`.
- Актуальный APK: 157 976 500 байт, SHA-256
  `A2E370AECA614136B2D494A65942330C72763731E752F7BF447FBD73A5B63521`.

## Что сделано

### F5. Локальные напоминания

- `flutter_local_notifications 22.3.2`, `timezone 0.11.2`,
  `flutter_timezone 5.1.1`.
- Одно уведомление на каждый выбранный день недели
  (`DateTimeComponents.dayOfWeekAndTime`), id детерминирован от `habitId` и
  дня (FNV-1a, стабилен между запусками).
- Неточные будильники `AndroidScheduleMode.inexactAllowWhileIdle` (±15 минут),
  без `SCHEDULE_EXACT_ALARM`.
- Канал `habit_reminders`: importance default, системный звук. Заголовок —
  название привычки, текст — «Отметьте привычку, когда будет удобно.».
- Android 13+: собственный диалог-объяснение → системный запрос
  `POST_NOTIFICATIONS`. При отказе привычка сохраняется без напоминания, в
  форме показывается подсказка «Открыть настройки».
- `RECEIVE_BOOT_COMPLETED` и `ScheduledNotificationBootReceiver` возвращают
  расписание после перезагрузки/обновления. При старте и выходе из фона
  расписание пересоздаётся (`syncAll`), поэтому смена часового пояса и
  разрешений подхватывается.
- Глобальный переключатель в настройках отменяет все уведомления, не стирая
  время напоминаний; повторное включение восстанавливает расписание.
- Ошибка планировщика не откатывает сохранение привычки.

### F6. Статистика

- `HabitStatistics` — чистые функции над `Habit.completedDates` и расписанием.
- Сводка 7 календарных дней: выполненные запланированные слоты / все
  запланированные слоты, сегодняшний невыполненный входит в знаменатель.
- Процент привычки за 30 дней (не раньше `createdAt`), текущая и лучшая серия
  по запланированным дням.
- Экран по макету `design/mockups/04-stats.html`: зелёная карточка сводки,
  «По привычкам · 30 дней», карточки с процентом и «Серия X · лучшая Y».
- Пустые состояния: нет привычек — CTA «Добавить привычку»; привычки без
  отметок — «0 из N», «Серия 0 · лучшая 0» и подсказка.
- Экран работает в светлой и тёмной теме, данные берутся из того же
  `HabitListController`, что и «Сегодня», без отдельных запросов к Hive.

## Ключевые решения

| Решение | Причина |
| --- | --- |
| Отдельный `ReminderScheduler` | Планировщик заменяем в тестах, UI не зависит от плагина |
| `ReminderPlan` без платформы | Время/id/дни проверяются unit-тестами без Android |
| `inexactAllowWhileIdle` | Бриф SUK-3: ±15 минут, без разрешения точных будильников |
| Пересоздание расписания целиком | Простое и надёжное поведение при редактировании/удалении |
| Статистика в domain | Одинаковые расчёты для экрана и тестов, Hive остаётся за репозиторием |
| Окно 30 дней с `createdAt` | Новая привычка не занижает процент прошлыми днями |

## Файлы

- `lib/features/reminders/domain/reminder_plan.dart`
- `lib/features/reminders/domain/reminder_scheduler.dart`
- `lib/features/reminders/data/flutter_local_reminder_scheduler.dart`
- `lib/features/statistics/domain/habit_statistics.dart`
- `lib/features/statistics/presentation/screens/statistics_screen.dart`
- `lib/features/statistics/presentation/widgets/*`
- `lib/features/habits/presentation/controllers/habit_list_controller.dart`
- `lib/features/habits/presentation/screens/habit_form_screen.dart`
- `lib/app/app_shell.dart`, `lib/app/app.dart`, `lib/main.dart`
- `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`,
  `android/app/src/main/res/drawable/ic_notification.xml`
- `test/features/reminders/*`, `test/features/statistics/*`,
  `test/features/habits/data/habit_hive_integration_test.dart`

## Тестовый сценарий напоминания

1. Установить APK на Android 13+.
2. Создать привычку с напоминанием на 2–3 минуты вперёд в выбранный день.
3. Разрешить уведомления, дождаться срабатывания (±15 минут), проверить
   открытие «Сегодня» по тапу.
4. Перезагрузить устройство — расписание должно сохраниться.
5. Выключить глобальный переключатель — уведомления не приходят; включить —
   возвращаются.

## Ограничения

- В окружении нет устройства/эмулятора Android, поэтому шаги 3–5 проверены
  unit-тестами планировщика и merged-манифестом, но не вручную на устройстве.
- Точность зависит от системного планировщика и энергосбережения прошивки.
- Release AAB и подпись для RuStore — отдельная задача.
