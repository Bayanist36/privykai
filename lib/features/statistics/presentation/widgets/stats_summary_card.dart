import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/statistics/domain/habit_statistics.dart';

class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({required this.summary, super.key});

  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final onAccent = palette.onAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'За последние 7 дней',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: onAccent.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.percent}%',
                      style: TextStyle(
                        fontSize: 36,
                        height: 40 / 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: onAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.completed} из ${summary.planned}',
                      style: TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w600,
                        color: onAccent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'запланировано',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onAccent.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: summary.ratio,
              minHeight: 6,
              color: onAccent,
              backgroundColor: onAccent.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Учитываются только запланированные дни.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: onAccent.withValues(alpha: 0.88)),
          ),
        ],
      ),
    );
  }
}
