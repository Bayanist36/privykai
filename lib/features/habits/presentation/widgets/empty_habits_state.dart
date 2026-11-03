import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_icons.dart';

@immutable
class HabitExample {
  const HabitExample({
    required this.name,
    required this.iconKey,
    required this.colorKey,
  });

  final String name;
  final String iconKey;
  final String colorKey;
}

class EmptyHabitsState extends StatelessWidget {
  const EmptyHabitsState({
    required this.onAddHabit,
    required this.onPickExample,
    super.key,
  });

  static const List<HabitExample> examples = <HabitExample>[
    HabitExample(name: 'Пить воду', iconKey: 'water', colorKey: 'green'),
    HabitExample(name: 'Читать 20 минут', iconKey: 'reading', colorKey: 'blue'),
    HabitExample(
      name: 'Гулять 10 000 шагов',
      iconKey: 'walk',
      colorKey: 'teal',
    ),
  ];

  final VoidCallback onAddHabit;
  final ValueChanged<HabitExample> onPickExample;

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
            SizedBox(
              width: 132,
              height: 132,
              child: CustomPaint(
                painter: _DashedCirclePainter(color: palette.borderStrong),
                child: Center(
                  child: Icon(
                    Icons.eco_outlined,
                    size: 44,
                    color: palette.accent,
                  ),
                ),
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
              'Добавьте первую — и отмечайте её одним тапом. '
              'Это займёт полминуты.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final example in examples) ...[
              _ExampleButton(
                example: example,
                onTap: () => onPickExample(example),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Добавить привычку'),
              style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 15, color: palette.green700),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Данные хранятся только на телефоне',
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: palette.green700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleButton extends StatelessWidget {
  const _ExampleButton({required this.example, required this.onTap});

  final HabitExample example;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final icon = HabitIcons.resolve(example.iconKey);

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  icon.glyph,
                  style: const TextStyle(fontSize: 20, height: 1),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    example.name,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const segments = 44;
    const gap = 0.035;
    for (var index = 0; index < segments; index++) {
      final start = (2 * 3.141592653589793 / segments) * index;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        (2 * 3.141592653589793 / segments) - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
