import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';

class FakeHabitRepository implements HabitRepository {
  FakeHabitRepository([List<Habit>? initial]) : habits = initial ?? <Habit>[];

  final List<Habit> habits;
  bool failOnWrite = false;
  int saveCalls = 0;

  @override
  Future<List<Habit>> getAll() async => List<Habit>.of(habits);

  @override
  Future<void> save(Habit habit) async {
    if (failOnWrite) {
      throw StateError('write failed');
    }
    saveCalls++;
    final index = habits.indexWhere((item) => item.id == habit.id);
    if (index == -1) {
      habits.add(habit);
    } else {
      habits[index] = habit;
    }
  }

  @override
  Future<void> delete(String id) async {
    if (failOnWrite) {
      throw StateError('write failed');
    }
    habits.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> deleteAll() async {
    if (failOnWrite) {
      throw StateError('write failed');
    }
    habits.clear();
  }
}
