import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/core/utils/russian_plural.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_colors.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_icons.dart';
import 'package:habit_tracker/features/habits/presentation/utils/date_labels.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    required this.habit,
    required this.onToggle,
    required this.onLongPress,
    super.key,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final isDone = habit.isCompletedToday;
    final streak = habit.currentStreak();
    final icon = HabitIcons.resolve(habit.iconKey);
    final color = HabitColors.resolve(habit.colorKey);

    return Semantics(
      button: true,
      toggled: isDone,
      label:
          '${habit.name}, ${isDone ? "выполнено" : "не выполнено"}, '
          '${RussianPlural.streak(streak)}',
      child: Material(
        color: isDone ? palette.accentSoft : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: isDone ? Colors.transparent : palette.borderSubtle,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onLongPress,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                      Text(
                        habit.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: 2,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 13,
                                color: streak == 0
                                    ? palette.textTertiary
                                    : palette.amber600,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  RussianPlural.streak(streak),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: streak == 0
                                        ? palette.textTertiary
                                        : isDone
                                        ? palette.green700
                                        : palette.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (habit.reminderMinutes != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 13,
                                  color: palette.textTertiary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    DateLabels.reminderSummary(
                                      habit.reminderMinutes!,
                                      intervalHours: habit.isIntervalReminder
                                          ? habit.reminderIntervalHours
                                          : null,
                                      windowEndMinutes:
                                          habit.reminderWindowEndMinutes,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CheckIndicator(isDone: isDone, color: color.base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  const _CheckIndicator({required this.isDone, required this.color});

  final bool isDone;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : palette.surface,
          border: Border.all(
            color: isDone ? color : palette.borderStrong,
            width: 2,
          ),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
