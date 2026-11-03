import 'package:habit_tracker/features/habits/domain/models/habit.dart';

/// Persistence boundary for habits. The presentation layer never talks to
/// Hive directly, which keeps storage replaceable and testable.
abstract interface class HabitRepository {
  Future<List<Habit>> getAll();

  Future<void> save(Habit habit);

  Future<void> delete(String id);

  Future<void> deleteAll();
}
