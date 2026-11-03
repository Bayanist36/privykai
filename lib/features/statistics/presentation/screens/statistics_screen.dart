import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:habit_tracker/features/statistics/domain/habit_statistics.dart';
import 'package:habit_tracker/features/statistics/presentation/widgets/habit_stat_card.dart';
import 'package:habit_tracker/features/statistics/presentation/widgets/stats_summary_card.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitListController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xs,
            AppSpacing.screenPadding,
            96,
          ),
          children: [
            Text(
              'Статистика',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.huge),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!controller.hasHabits)
              const _EmptyStatsState()
            else
              ..._buildStats(context, controller),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStats(
    BuildContext context,
    HabitListController controller,
  ) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final summary = HabitStatistics.summary(controller.habits);
    final hasCompletions = HabitStatistics.hasAnyCompletion(controller.habits);

    return [
      StatsSummaryCard(summary: summary),
      if (!hasCompletions) ...[
        const SizedBox(height: AppSpacing.md),
        Text(
          'Отметьте первую привычку — здесь появится прогресс.',
          style: textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.xxl),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('По привычкам', style: textTheme.titleLarge),
          Text(
            '30 дней',
            style: textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      for (final habit in controller.habits) ...[
        HabitStatCard(habit: habit),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _EmptyStatsState extends StatelessWidget {
  const _EmptyStatsState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: palette.surfaceSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.insert_chart_outlined_rounded,
            size: 48,
            color: palette.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Пока нет привычек',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Добавьте первую — и здесь появится прогресс. Это займёт полминуты.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const HabitFormScreen()),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Добавить привычку'),
          style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
        ),
      ],
    );
  }
}
