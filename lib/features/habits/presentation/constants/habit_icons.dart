import 'package:flutter/material.dart';

/// Emoji options available when creating or editing a habit.
///
/// Keys are persisted, so they must stay stable even if a glyph or label
/// changes. `exercise` is the SUK-5 key for «Тренировка» and is kept for
/// backwards compatibility.
@immutable
class HabitIconOption {
  const HabitIconOption({
    required this.key,
    required this.label,
    required this.glyph,
  });

  final String key;
  final String label;
  final String glyph;

  /// Material fallback used by compact statistics cards and older widgets.
  IconData get icon => switch (key) {
    'water' => Icons.water_drop_outlined,
    'run' => Icons.directions_run_outlined,
    'exercise' => Icons.fitness_center_outlined,
    'reading' => Icons.menu_book_outlined,
    'sleep' => Icons.bedtime_outlined,
    'meditation' => Icons.self_improvement_outlined,
    'walk' => Icons.directions_walk_outlined,
    'nutrition' => Icons.restaurant_outlined,
    'teeth' => Icons.clean_hands_outlined,
    'morning' => Icons.wb_sunny_outlined,
    'vitamins' => Icons.medication_outlined,
    'journal' => Icons.edit_note_outlined,
    'music' => Icons.music_note_outlined,
    'cleaning' => Icons.cleaning_services_outlined,
    'quit' => Icons.smoke_free_outlined,
    _ => Icons.eco_outlined,
  };
}

abstract final class HabitIcons {
  static const String fallbackKey = 'other';

  static const List<HabitIconOption> options = <HabitIconOption>[
    HabitIconOption(key: 'water', label: 'Вода', glyph: '💧'),
    HabitIconOption(key: 'run', label: 'Бег', glyph: '🏃'),
    HabitIconOption(key: 'exercise', label: 'Тренировка', glyph: '💪'),
    HabitIconOption(key: 'reading', label: 'Чтение', glyph: '📖'),
    HabitIconOption(key: 'sleep', label: 'Сон', glyph: '😴'),
    HabitIconOption(key: 'meditation', label: 'Медитация', glyph: '🧘'),
    HabitIconOption(key: 'walk', label: 'Прогулка', glyph: '🚶'),
    HabitIconOption(key: 'nutrition', label: 'Питание', glyph: '🥗'),
    HabitIconOption(key: 'teeth', label: 'Зубы', glyph: '🦷'),
    HabitIconOption(key: 'morning', label: 'Утро', glyph: '☀️'),
    HabitIconOption(key: 'vitamins', label: 'Витамины', glyph: '💊'),
    HabitIconOption(key: 'journal', label: 'Дневник', glyph: '✍️'),
    HabitIconOption(key: 'music', label: 'Музыка', glyph: '🎸'),
    HabitIconOption(key: 'cleaning', label: 'Уборка', glyph: '🧹'),
    HabitIconOption(key: 'quit', label: 'Отказ', glyph: '🚭'),
    HabitIconOption(key: fallbackKey, label: 'Другое', glyph: '🌱'),
  ];

  static HabitIconOption resolve(String key) {
    return options.firstWhere(
      (option) => option.key == key,
      orElse: () => options.last,
    );
  }
}
