import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';

class ReminderSyncCall {
  const ReminderSyncCall({
    required this.habits,
    required this.enabled,
    this.evening,
  });

  final List<Habit> habits;
  final bool enabled;
  final EveningReminder? evening;
}

class FakeReminderScheduler implements ReminderScheduler {
  final List<ReminderSyncCall> syncCalls = <ReminderSyncCall>[];
  bool notificationsEnabled = true;
  bool permissionGranted = true;
  bool permissionRequested = false;
  bool settingsOpened = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    notificationsEnabled = permissionGranted;
    return permissionGranted;
  }

  @override
  Future<void> openNotificationSettings() async {
    settingsOpened = true;
  }

  @override
  Future<void> syncAll(
    List<Habit> habits, {
    bool enabled = true,
    EveningReminder? evening,
  }) async {
    syncCalls.add(
      ReminderSyncCall(
        habits: List<Habit>.of(habits),
        enabled: enabled,
        evening: evening,
      ),
    );
  }
}
