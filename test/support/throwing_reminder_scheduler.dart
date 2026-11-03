import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';

/// Simulates a platform plugin that cannot initialize (BUG-02 release case).
class ThrowingReminderScheduler implements ReminderScheduler {
  @override
  Future<void> initialize() async => throw StateError('plugin init failed');

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    return false;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    return false;
  }

  @override
  Future<void> openNotificationSettings() async => initialize();

  @override
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  }) async {
    await initialize();
  }
}
