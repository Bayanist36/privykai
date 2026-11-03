import 'package:hive/hive.dart';

import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';

/// Hand-written Hive adapter: no code generation step, so a clean checkout
/// builds with `flutter pub get` only.
///
/// Field layout (append-only, typeId 13):
/// 0 id, 1 name, 2 iconKey, 3 reminderMinutes, 4 createdAt, 5 completedDates,
/// 6 colorKey, 7 weekdaysMask, 8 reminderIntervalHours,
/// 9 reminderWindowEndMinutes.
///
/// Documents written by older builds have fewer fields. Missing fields fall
/// back to the old behaviour (green colour, every day, single reminder), so
/// completions and reminder times survive the migration.
///
/// Hive reserves type ids 0–12 for its built-in `FrameValueType` values
/// (`nullT = 0`, `intT = 1`, …). Registering a custom adapter in that range
/// makes Hive parse the frame as a built-in type, so the first field reads as
/// `null`. 13 is the first safe id (BUG-01). Do not reuse or renumber it:
/// changing it makes existing user boxes unreadable.
class HabitAdapter extends TypeAdapter<Habit> {
  static const int habitTypeId = 13;

  @override
  final int typeId = habitTypeId;

  static const int _fieldCount = 10;

  @override
  Habit read(BinaryReader reader) {
    // Read the field count once. Reading it inside the loop condition would
    // consume one byte per iteration and leave the map empty on reopen.
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return fromFields(fields);
  }

  static Habit fromFields(Map<int, dynamic> fields) {
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      iconKey: fields[2] as String,
      reminderMinutes: fields[3] as int?,
      createdAt: fields[4] as DateTime,
      completedDates: (fields[5] as List?)?.cast<String>() ?? const <String>[],
      colorKey: fields[6] as String? ?? Habit.defaultColorKey,
      weekdaysMask: fields[7] as int? ?? Weekdays.everyDayMask,
      reminderIntervalHours: fields[8] as int?,
      reminderWindowEndMinutes:
          fields[9] as int? ?? Habit.defaultWindowEndMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, Habit habit) {
    writer
      ..writeByte(_fieldCount)
      ..writeByte(0)
      ..write(habit.id)
      ..writeByte(1)
      ..write(habit.name)
      ..writeByte(2)
      ..write(habit.iconKey)
      ..writeByte(3)
      ..write(habit.reminderMinutes)
      ..writeByte(4)
      ..write(habit.createdAt)
      ..writeByte(5)
      ..write(habit.completedDates)
      ..writeByte(6)
      ..write(habit.colorKey)
      ..writeByte(7)
      ..write(habit.weekdaysMask)
      ..writeByte(8)
      ..write(habit.reminderIntervalHours)
      ..writeByte(9)
      ..write(habit.reminderWindowEndMinutes);
  }
}
