import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/core/utils/russian_plural.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:habit_tracker/features/habits/presentation/utils/date_labels.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/empty_habits_state.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_tile.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/no_habits_today_state.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/progress_card.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HabitListController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateLabels.todayEyebrow(DateTime.now()),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Сегодня', style: Theme.of(context).textTheme.headlineLarge),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ErrorBanner(
                  message: controller.errorMessage!,
                  onDismiss: controller.clearError,
                ),
              ],
              Expanded(child: _buildContent(context, controller)),
            ],
          ),
        ),
      ),
      floatingActionButton: controller.todayTotal == 0
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(context),
              tooltip: 'Добавить привычку',
              child: const Icon(Icons.add_rounded, size: 26),
            ),
    );
  }

  Widget _buildContent(BuildContext context, HabitListController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.totalCount == 0) {
      return EmptyHabitsState(
        onAddHabit: () => _openForm(context),
        onPickExample: (example) => _openForm(context, example: example),
      );
    }

    if (controller.todayTotal == 0) {
      return NoHabitsTodayState(
        otherHabitsCount: controller.unscheduledTodayCount,
        onAddHabit: () => _openForm(context),
      );
    }

    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 96),
      children: [
        ProgressCard(
          completed: controller.completedToday,
          total: controller.todayTotal,
        ),
        const SizedBox(height: AppSpacing.xxl),
        _SectionHead(
          meta: '${controller.completedToday} из ${controller.todayTotal}',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final habit in controller.todayHabits) ...[
          HabitTile(
            habit: habit,
            onToggle: () => _toggleHabit(context, habit),
            onLongPress: () => _showHabitActions(context, habit),
          ),
          const SizedBox(height: 10),
        ],
        if (controller.unscheduledTodayCount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color: palette.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Ещё ${controller.unscheduledTodayCount} '
                    '${RussianPlural.habits(controller.unscheduledTodayCount)} '
                    '— в другие дни недели',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleHabit(BuildContext context, Habit habit) async {
    HapticFeedback.lightImpact();

    final controller = context.read<HabitListController>();
    final messenger = ScaffoldMessenger.of(context);
    final wasCompleted = habit.isCompletedToday;
    final updated = await controller.toggleCompletion(habit);

    if (!context.mounted) {
      return;
    }

    messenger.hideCurrentSnackBar();
    if (updated == null) {
      final error = controller.errorMessage;
      if (error != null) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        controller.clearError();
      }
      return;
    }

    if (wasCompleted) {
      messenger.showSnackBar(const SnackBar(content: Text('Отметка снята')));
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('Выполнено. Серия: ${updated.currentStreak()}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            // The snackbar lives for five seconds; the habit may have been
            // toggled again meanwhile, so re-read the current state.
            Habit? current;
            for (final item in controller.habits) {
              if (item.id == updated.id) {
                current = item;
              }
            }
            if (current == null || !current.isCompletedToday) {
              return;
            }
            controller.toggleCompletion(current);
          },
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    Habit? habit,
    HabitExample? example,
  }) async {
    final result = await Navigator.of(context).push<HabitFormResult>(
      MaterialPageRoute<HabitFormResult>(
        builder: (_) => HabitFormScreen(
          habit: habit,
          initialName: example?.name,
          initialIconKey: example?.iconKey,
          initialColorKey: example?.colorKey,
        ),
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _showHabitActions(BuildContext context, Habit habit) async {
    final palette = context.palette;
    final action = await showModalBottomSheet<_HabitAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                onTap: () => Navigator.of(sheetContext).pop(_HabitAction.edit),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: palette.danger,
                ),
                title: Text(
                  'Удалить привычку',
                  style: TextStyle(
                    color: palette.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_HabitAction.delete),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.close_rounded),
                title: const Text('Отмена'),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    switch (action) {
      case _HabitAction.edit:
        await _openForm(context, habit: habit);
      case _HabitAction.delete:
        await _confirmDelete(context, habit);
      case null:
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Удалить «${habit.name}»?'),
        content: const Text(
          'История и серия будут удалены безвозвратно. '
          'Остальные привычки не изменятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: palette.danger,
              backgroundColor: palette.dangerSoft,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final controller = context.read<HabitListController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.deleteHabit(habit);

    if (!context.mounted) {
      return;
    }
    messenger.hideCurrentSnackBar();
    final error = controller.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      controller.clearError();
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text('«${habit.name}» удалена')));
  }
}

enum _HabitAction { edit, delete }

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.meta});

  final String meta;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Привычки', style: textTheme.titleLarge),
        Text(
          meta,
          style: textTheme.labelLarge?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: palette.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.textPrimary),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Закрыть',
            icon: const Icon(Icons.close_rounded, size: 18),
            color: palette.textSecondary,
          ),
        ],
      ),
    );
  }
}
