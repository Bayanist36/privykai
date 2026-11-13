import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/reminders/domain/local_time_zone.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';

/// Android implementation backed by `flutter_local_notifications`.
///
/// One recurring notification is scheduled per selected weekday with
/// `DateTimeComponents.dayOfWeekAndTime` and an inexact alarm (±15 minutes),
/// so the app does not need `SCHEDULE_EXACT_ALARM`.
class FlutterLocalReminderScheduler implements ReminderScheduler {
  FlutterLocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'habit_reminders';
  static const String channelName = 'Напоминания о привычках';
  static const String channelDescription =
      'Напоминания по расписанию привычки: один раз в день или через '
      'выбранный интервал.';

  static const String eveningChannelId = 'evening_check';
  static const String eveningChannelName = 'Вечерняя проверка';
  static const String eveningChannelDescription =
      'Одно напоминание вечером проверить, всё ли отмечено.';

  /// Payload of the evening reminder so the app can route it if needed.
  static const String eveningPayload = 'evening_check';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );

    try {
      await _plugin.initialize(settings: settings);

      final android = _android;
      if (android != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        );
        await android.createNotificationChannel(channel);

        const eveningChannel = AndroidNotificationChannel(
          eveningChannelId,
          eveningChannelName,
          description: eveningChannelDescription,
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        );
        await android.createNotificationChannel(eveningChannel);
      }

      _initialized = true;
    } catch (error, stackTrace) {
      // A broken release resource (BUG-02) or a platform error must surface
      // to the caller instead of turning the reminder switch into a no-op.
      debugPrint('Reminder plugin initialization failed: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    final android = _android;
    if (android == null) {
      return false;
    }
    return await android.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _android;
    if (android == null) {
      return false;
    }
    final granted = await android.requestNotificationsPermission();
    if (granted != null) {
      return granted;
    }
    return await android.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> openNotificationSettings() async {
    await initialize();
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  }) async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();

    if (!enabled || !await areNotificationsEnabled()) {
      return;
    }

    final now = DateTime.now();
    final planned = <PlannedReminder>[];
    final data = <int, _ScheduledNotification>{};

    for (final habit in habits) {
      if (habit.weekdaysMask == 0 || !habit.hasReminder) {
        continue;
      }
      for (final reminder in ReminderPlan.planFor(habit, now: now)) {
        planned.add(reminder);
        data[reminder.id] = _ScheduledNotification(
          title: habit.name,
          body: habit.isIntervalReminder
              ? 'Пора отметить привычку.'
              : 'Отметьте привычку, когда будет удобно.',
          payload: habit.id,
          details: _habitDetails,
        );
      }
    }

    // A fully completed day needs no "did you finish?" nudge. The other
    // weekdays keep their weekly slot.
    final effectiveEvening = ReminderPlan.effectiveEvening(
      evening: evening,
      habits: habits,
      now: now,
    );

    for (final reminder in ReminderPlan.eveningPlan(
      evening: effectiveEvening,
      now: now,
    )) {
      planned.add(reminder);
      data[reminder.id] = const _ScheduledNotification(
        title: 'Как прошёл день?',
        body: 'Отметьте выполненные привычки, пока не закончился день.',
        payload: eveningPayload,
        details: _eveningDetails,
      );
    }

    // Keep the nearest reminders when a plan exceeds the safe pending-alarm
    // count; the distant tail is dropped instead of the closest slots.
    for (final reminder in ReminderPlan.capToLimit(planned)) {
      final item = data[reminder.id];
      if (item == null) {
        continue;
      }
      await _schedule(
        id: reminder.id,
        dateTime: reminder.dateTime,
        details: item.details,
        title: item.title,
        body: item.body,
        payload: item.payload,
        repeatsWeekly: reminder.repeatsWeekly,
      );
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _configureLocalTimeZone() async {
    String? identifier;
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      identifier = timeZone.identifier;
    } catch (error) {
      debugPrint('Could not read device timezone: $error');
    }

    final resolved = LocalTimeZone.resolveName(identifier);
    if (resolved != null) {
      tz.setLocalLocation(tz.getLocation(resolved));
      return;
    }

    // Never fall back to UTC silently: use the device's current offset so a
    // reminder set for 08:00 still fires at 08:00 local time (BUG-06).
    final offset = DateTime.now().timeZoneOffset;
    final fallback = LocalTimeZone.fixedOffset(offset);
    tz.setLocalLocation(fallback);
    debugPrint(
      'Could not resolve timezone "$identifier"; using device offset '
      '$offset (${fallback.name}).',
    );
  }

  static const NotificationDetails _habitDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  static const NotificationDetails _eveningDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      eveningChannelId,
      eveningChannelName,
      channelDescription: eveningChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    ),
  );

  Future<void> _schedule({
    required int id,
    required DateTime dateTime,
    required NotificationDetails details,
    required String title,
    required String body,
    required String payload,
    bool repeatsWeekly = true,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime(
        tz.local,
        dateTime.year,
        dateTime.month,
        dateTime.day,
        dateTime.hour,
        dateTime.minute,
      ),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
      // A suppressed evening slot is a one-shot next week: the weekly match
      // compares only weekday + time and would still fire today (QA-24-01).
      matchDateTimeComponents: repeatsWeekly
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
    );
  }
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.title,
    required this.body,
    required this.payload,
    required this.details,
  });

  final String title;
  final String body;
  final String payload;
  final NotificationDetails details;
}
