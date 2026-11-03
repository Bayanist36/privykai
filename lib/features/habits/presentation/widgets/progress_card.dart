import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/core/utils/russian_plural.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({required this.completed, required this.total, super.key});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).round();
    final remaining = total - completed;
    final onAccent = palette.onAccent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
                      'Выполнено сегодня',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: onAccent.withValues(alpha: 0.72)),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$completed',
                            style: TextStyle(
                              fontSize: 28,
                              height: 34 / 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              color: onAccent,
                            ),
                          ),
                          TextSpan(
                            text: ' из $total',
                            style: TextStyle(
                              fontSize: 15,
                              height: 22 / 15,
                              fontWeight: FontWeight.w500,
                              color: onAccent.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w600,
                    color: onAccent.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: onAccent,
              backgroundColor: onAccent.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining == 0
                ? 'Все привычки на сегодня выполнены'
                : 'Осталось $remaining ${RussianPlural.habits(remaining)}',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: onAccent.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}
