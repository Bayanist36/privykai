import 'package:flutter/material.dart';

import 'package:habit_tracker/features/habits/domain/models/habit.dart';

@immutable
class HabitColorOption {
  const HabitColorOption({
    required this.key,
    required this.label,
    required this.base,
    required this.soft,
  });

  final String key;
  final String label;
  final Color base;
  final Color soft;
}

/// Six habit colours from SUK-4. The key is persisted; `base` fills the
/// completion indicator and `soft` fills the emoji tile.
abstract final class HabitColors {
  static const List<HabitColorOption> options = <HabitColorOption>[
    HabitColorOption(
      key: 'green',
      label: 'Зелёный',
      base: Color(0xFF2A7052),
      soft: Color(0xFFE4EFE8),
    ),
    HabitColorOption(
      key: 'blue',
      label: 'Синий',
      base: Color(0xFF3C6E9F),
      soft: Color(0xFFE6EEF6),
    ),
    HabitColorOption(
      key: 'amber',
      label: 'Янтарный',
      base: Color(0xFFB87120),
      soft: Color(0xFFF8E9D2),
    ),
    HabitColorOption(
      key: 'coral',
      label: 'Коралловый',
      base: Color(0xFFB45A4A),
      soft: Color(0xFFF7E4DF),
    ),
    HabitColorOption(
      key: 'violet',
      label: 'Фиолетовый',
      base: Color(0xFF6B5B95),
      soft: Color(0xFFECE8F4),
    ),
    HabitColorOption(
      key: 'teal',
      label: 'Бирюзовый',
      base: Color(0xFF2F7C77),
      soft: Color(0xFFE1F0EE),
    ),
  ];

  static HabitColorOption resolve(String key) {
    return options.firstWhere(
      (option) => option.key == key,
      orElse: () =>
          options.firstWhere((option) => option.key == Habit.defaultColorKey),
    );
  }
}
