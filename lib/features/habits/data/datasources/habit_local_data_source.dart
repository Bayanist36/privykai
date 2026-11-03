import 'package:hive/hive.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';

/// Thin wrapper around the Hive box. Hive operations are synchronous, but the
/// methods return futures so the repository contract stays storage-agnostic.
class HabitLocalDataSource {
  HabitLocalDataSource(this._box);

  final Box<Habit> _box;

  Future<List<Habit>> getAll() async {
    final habits = _box.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return habits;
  }

  Future<void> save(Habit habit) async {
    await _box.put(habit.id, habit);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }
}
