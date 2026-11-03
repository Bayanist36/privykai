import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_colors.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_icons.dart';
import 'package:habit_tracker/features/statistics/domain/habit_statistics.dart';

class HabitStatCard extends StatelessWidget {
  const HabitStatCard({required this.habit, super.key});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final stats = HabitStatistics.habitStats(habit);
    final icon = HabitIcons.resolve(habit.iconKey);
    final color = HabitColors.resolve(habit.colorKey);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.soft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              icon.glyph,
              style: const TextStyle(fontSize: 21, height: 1),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${stats.percent}%',
                      style: TextStyle(
                        fontSize: 15,
                        height: 22 / 15,
                        fontWeight: FontWeight.w600,
                        color: palette.green700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Серия ${stats.currentStreak} · лучшая ${stats.bestStreak}',
                  style: textTheme.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
