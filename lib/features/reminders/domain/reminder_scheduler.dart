import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';

/// Platform boundary for local habit reminders.
abstract interface class ReminderScheduler {
  /// Prepares the plugin, timezone database and notification channel.
  Future<void> initialize();

  /// Whether the system currently allows the app to post notifications.
  Future<bool> areNotificationsEnabled();

  /// Shows the Android 13+ permission prompt when needed.
  ///
  /// Returns `true` when notifications are allowed after the call.
  Future<bool> requestPermission();

  /// Opens the system notification settings for this app.
  Future<void> openNotificationSettings();

  /// Replaces all scheduled notifications with the current habit schedules.
  ///
  /// When [enabled] is `false`, every pending notification is cancelled while
  /// habit-level reminder settings stay intact. [evening] adds one extra
  /// reminder per weekday; `null` disables it.
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  });
}

/// Scheduler used in tests and on platforms without notification support.
///
/// It records nothing and never posts notifications; permission checks report
/// success so UI flows can be exercised without the platform plugin.
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> openNotificationSettings() async {}

  @override
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  }) async {}
}
