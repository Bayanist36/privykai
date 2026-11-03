import 'package:habit_tracker/features/habits/data/datasources/habit_local_data_source.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/domain/repositories/habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl(this._localDataSource);

  final HabitLocalDataSource _localDataSource;

  @override
  Future<List<Habit>> getAll() => _localDataSource.getAll();

  @override
  Future<void> save(Habit habit) => _localDataSource.save(habit);

  @override
  Future<void> delete(String id) => _localDataSource.delete(id);

  @override
  Future<void> deleteAll() => _localDataSource.deleteAll();
}
