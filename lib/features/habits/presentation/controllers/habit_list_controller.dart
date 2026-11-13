// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_icons.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';
import 'package:habit_tracker/features/widget/domain/home_widget_bridge.dart';

/// Owns the habit list state and all mutations.
///
/// The controller is deliberately storage-agnostic and exposes plain
/// [ChangeNotifier] state; screens read it through Provider.
class HabitListController extends ChangeNotifier {
  HabitListController(
    this._repository, {
    ReminderScheduler? reminders,
    HomeWidgetBridge? homeWidget,
    Uuid? uuid,
  }) : _reminders = reminders,
       _homeWidget = homeWidget,
       _uuid = uuid ?? const Uuid();

  static const int maxNameLength = Habit.maxNameLength;

  final HabitRepository _repository;
  final ReminderScheduler? _reminders;
  final HomeWidgetBridge? _homeWidget;
  final Uuid _uuid;

  bool _remindersEnabled = true;
  EveningReminder? _eveningReminder;

  List<Habit> _habits = const <Habit>[];
  bool _isLoading = true;
  String? _errorMessage;
  bool _disposed = false;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  bool get isLoading => _isLoading;
  bool get isEmpty => !_isLoading && _habits.isEmpty;
  bool get hasHabits => _habits.isNotEmpty;
  String? get errorMessage => _errorMessage;

  int get totalCount => _habits.length;

  /// Habits whose schedule includes today and that already exist today.
  List<Habit> get todayHabits {
    final today = DateTime.now();
    return _habits.where((habit) => habit.isScheduledOn(today)).toList();
  }

  int get todayTotal => todayHabits.length;

  int get unscheduledTodayCount => totalCount - todayTotal;

  int completedOn(DateTime day) => _habits
      .where((habit) => habit.isScheduledOn(day) && habit.isCompletedOn(day))
      .length;

  int get completedToday => completedOn(DateTime.now());

  int get remainingToday => todayTotal - completedToday;

  double get todayProgress => todayTotal == 0 ? 0 : completedToday / todayTotal;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      _habits = await _repository.getAll();
    } catch (error) {
      _errorMessage = 'Не удалось загрузить привычки. Попробуйте ещё раз.';
    } finally {
      _isLoading = false;
      _notify();
    }
    if (_errorMessage == null) {
      await syncReminders();
      await _pushWidget();
    }
  }

  Future<bool> addHabit({
    required String name,
    required String iconKey,
    String colorKey = Habit.defaultColorKey,
    int weekdaysMask = Weekdays.everyDayMask,
    int? reminderMinutes,
    int? reminderIntervalHours,
    int reminderWindowEndMinutes = Habit.defaultWindowEndMinutes,
  }) async {
    final validationError = _validate(name: name, weekdaysMask: weekdaysMask);
    if (validationError != null) {
      _errorMessage = validationError;
      _notify();
      return false;
    }

    final habit = Habit(
      id: _uuid.v4(),
      name: name.trim(),
      iconKey: iconKey,
      colorKey: colorKey,
      weekdaysMask: weekdaysMask,
      createdAt: DateTime.now(),
      reminderMinutes: reminderMinutes,
      reminderIntervalHours: reminderIntervalHours,
      reminderWindowEndMinutes: reminderWindowEndMinutes,
    );

    try {
      await _repository.save(habit);
      _habits = <Habit>[..._habits, habit]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _errorMessage = null;
      _notify();
      await syncReminders();
      await _pushWidget();
      return true;
    } catch (error) {
      _errorMessage = 'Не удалось сохранить привычку. Попробуйте ещё раз.';
      _notify();
      return false;
    }
  }

  /// Updates every editable field while keeping id, creation date and the
  /// completion history. Past completions are never rewritten.
  Future<bool> updateHabit({
    required Habit habit,
    required String name,
    required String iconKey,
    required String colorKey,
    required int weekdaysMask,
    int? reminderMinutes,
    int? reminderIntervalHours,
    int reminderWindowEndMinutes = Habit.defaultWindowEndMinutes,
  }) async {
    final validationError = _validate(name: name, weekdaysMask: weekdaysMask);
    if (validationError != null) {
      _errorMessage = validationError;
      _notify();
      return false;
    }

    final updated = habit.copyWith(
      name: name.trim(),
      iconKey: iconKey,
      colorKey: colorKey,
      weekdaysMask: weekdaysMask,
      reminderMinutes: reminderMinutes,
      reminderIntervalHours: reminderIntervalHours,
      reminderWindowEndMinutes: reminderWindowEndMinutes,
      clearReminder: reminderMinutes == null,
      clearReminderInterval: reminderIntervalHours == null,
    );

    try {
      await _repository.save(updated);
      _replace(updated);
      _errorMessage = null;
      _notify();
      await syncReminders();
      await _pushWidget();
      return true;
    } catch (error) {
      _errorMessage = 'Не удалось сохранить изменения. Попробуйте ещё раз.';
      _notify();
      return false;
    }
  }

  /// Toggles today's completion and returns the persisted habit.
  ///
  /// Returns `null` when the write failed; the caller can then keep the
  /// previous UI/snackbar state.
  Future<Habit?> toggleCompletion(Habit habit, {DateTime? day}) async {
    final updated = habit.toggleCompletion(day ?? DateTime.now());
    Habit? result;
    try {
      await _repository.save(updated);
      _replace(updated);
      _errorMessage = null;
      result = updated;
    } catch (error) {
      _errorMessage = 'Не удалось обновить привычку. Попробуйте ещё раз.';
    }
    _notify();
    await _pushWidget();
    if (_eveningReminder != null) {
      // Completion changes whether today's evening nudge is still needed.
      await syncReminders();
    }
    return result;
  }

  Future<void> deleteHabit(Habit habit) async {
    try {
      await _repository.delete(habit.id);
      _habits = _habits.where((item) => item.id != habit.id).toList();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Не удалось удалить привычку. Попробуйте ещё раз.';
    }
    _notify();
    if (_errorMessage == null) {
      await syncReminders();
      await _pushWidget();
    }
  }

  Future<void> restoreHabit(Habit habit) async {
    try {
      await _repository.save(habit);
      _habits = <Habit>[..._habits, habit]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Не удалось восстановить привычку.';
    }
    _notify();
    if (_errorMessage == null) {
      await syncReminders();
      await _pushWidget();
    }
  }

  /// Re-schedules notifications with the platform scheduler.
  ///
  /// [enabled] mirrors the global reminders switch from Settings; turning it
  /// off cancels every pending notification without touching habit data.
  Future<void> syncReminders({bool? enabled}) async {
    if (enabled != null) {
      _remindersEnabled = enabled;
    }
    try {
      await _reminders?.syncAll(
        _habits,
        enabled: _remindersEnabled,
        evening: _eveningReminder,
      );
    } catch (error) {
      debugPrint('Could not schedule reminders: $error');
    }
  }

  /// Applies the global evening reminder from settings and re-schedules when it
  /// changed. Passing null switches the evening reminder off.
  /// [evening] is null when the reminder is switched off.
  Future<void> setEveningReminder(EveningReminder? evening) async {
    if (_eveningReminder == evening) {
      return;
    }
    _eveningReminder = evening;
    await syncReminders();
  }

  /// Replaces the whole habit list, used by the import flow.
  Future<bool> replaceAll(List<Habit> habits) async {
    try {
      await _repository.deleteAll();
      for (final habit in habits) {
        await _repository.save(habit);
      }
      _habits = <Habit>[...habits]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _errorMessage = null;
      _notify();
      await syncReminders();
      await _pushWidget();
      return true;
    } catch (error) {
      _errorMessage = 'Не удалось восстановить данные. Попробуйте ещё раз.';
      _notify();
      return false;
    }
  }

  /// Pushes today's progress to the home screen widget.
  Future<void> refreshWidget() => _pushWidget();

  Future<void> _pushWidget() async {
    final bridge = _homeWidget;
    if (bridge == null) {
      return;
    }
    final today = todayHabits;
    final pending = today
        .where((habit) => !habit.isCompletedToday)
        .map((habit) => habit.name)
        .toList();

    var topName = today.isEmpty ? null : today.first.name;
    var topStreak = 0;
    final items = <HomeWidgetItem>[];
    for (final habit in today) {
      final streak = habit.currentStreak();
      if (streak > topStreak) {
        topStreak = streak;
        topName = habit.name;
      }
      if (items.length < 3) {
        items.add(
          HomeWidgetItem(
            name: habit.name,
            done: habit.isCompletedToday,
            streak: streak,
            emoji: HabitIcons.resolve(habit.iconKey).glyph,
          ),
        );
      }
    }

    await bridge.push(
      HomeWidgetSnapshot(
        completed: today.length - pending.length,
        total: today.length,
        pendingNames: pending,
        date: DateKey.from(DateTime.now()),
        items: items,
        topName: topStreak > 0 ? topName : null,
        topStreak: topStreak,
      ),
    );
  }

  Future<bool> clearAll() async {
    try {
      await _repository.deleteAll();
      _habits = const <Habit>[];
      _errorMessage = null;
      _notify();
      await syncReminders();
      await _pushWidget();
      return true;
    } catch (error) {
      _errorMessage = 'Не удалось сбросить данные. Попробуйте ещё раз.';
      _notify();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    _notify();
  }

  String? _validate({required String name, required int weekdaysMask}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Введите название привычки.';
    }
    if (trimmed.runes.length > maxNameLength) {
      return 'Название не длиннее $maxNameLength символов.';
    }
    if (!Weekdays.isValid(weekdaysMask)) {
      return 'Выберите хотя бы один день недели.';
    }
    return null;
  }

  void _replace(Habit updated) {
    _habits = _habits
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
