import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/core/utils/russian_plural.dart';

class NoHabitsTodayState extends StatelessWidget {
  const NoHabitsTodayState({
    required this.onAddHabit,
    this.otherHabitsCount = 0,
    super.key,
  });

  final VoidCallback onAddHabit;
  final int otherHabitsCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: palette.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 44,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'На сегодня привычек нет',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'По расписанию сегодня отдых. Завтра привычки вернутся — '
              'или добавьте новую.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            if (otherHabitsCount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'В расписании $otherHabitsCount '
                '${RussianPlural.habits(otherHabitsCount)}, '
                'но не на сегодня.',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Добавить привычку'),
              style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
            ),
          ],
        ),
      ),
    );
  }
}
