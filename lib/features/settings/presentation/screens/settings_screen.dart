import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_info.dart';
import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/utils/date_labels.dart';
import 'package:habit_tracker/features/settings/domain/models/app_settings.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';
import 'package:habit_tracker/features/settings/presentation/screens/privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onDataReset, super.key});

  final VoidCallback onDataReset;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final settings = context.watch<SettingsController>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xs,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            Text('Настройки', style: textTheme.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: palette.green700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Данные хранятся только на этом устройстве',
                      style: textTheme.labelSmall?.copyWith(
                        color: palette.green700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _GroupLabel('Оформление'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Тема',
                  subtitle: 'Применяется сразу, без перезапуска',
                  value: _themeLabel(settings.settings.themeMode),
                  onTap: () => _pickTheme(context, settings),
                ),
              ],
            ),
            const _GroupLabel('Напоминания'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Напоминания',
                  subtitle: 'Одно уведомление в день',
                  trailing: Switch.adaptive(
                    value: settings.settings.remindersEnabled,
                    onChanged: (value) => _setReminders(context, value),
                  ),
                ),
                _SettingsRow(
                  icon: Icons.schedule_rounded,
                  title: 'Время по умолчанию',
                  subtitle: 'Для новых привычек',
                  value: DateLabels.reminderTime(
                    settings.settings.defaultReminderMinutes,
                  ),
                  onTap: () => _pickDefaultTime(context, settings),
                ),
                _SettingsRow(
                  icon: Icons.nightlight_outlined,
                  title: 'Вечернее напоминание',
                  subtitle: 'Одно напоминание вечером проверить невыполненное',
                  trailing: Switch.adaptive(
                    value: settings.settings.eveningReminderEnabled,
                    onChanged: (value) => _setEveningReminder(context, value),
                  ),
                ),
                if (settings.settings.eveningReminderEnabled)
                  _SettingsRow(
                    icon: Icons.schedule_rounded,
                    title: 'Время вечернего напоминания',
                    subtitle: 'По умолчанию 20:00',
                    value: DateLabels.reminderTime(
                      settings.settings.eveningReminderMinutes,
                    ),
                    onTap: () => _pickEveningTime(context, settings),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'В дни по расписанию: один раз в день или каждые '
                      'N часов. Вечернее напоминание приходит одно на весь '
                      'список привычек.',
                      style: textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            const _GroupLabel('Данные'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Сбросить все данные',
                  subtitle: 'Привычки и история исчезнут с телефона',
                  danger: true,
                  onTap: () => _resetData(context),
                ),
              ],
            ),
            const _GroupLabel('О приложении'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: 'Версия',
                  value: AppInfo.version,
                ),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Политика конфиденциальности',
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: palette.textTertiary,
                  ),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppInfo.copyright,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTheme(
    BuildContext context,
    SettingsController controller,
  ) async {
    final palette = context.palette;
    final selected = await showDialog<AppThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Тема'),
        children: [
          for (final mode in AppThemeMode.values)
            Semantics(
              selected: controller.settings.themeMode == mode,
              button: true,
              child: SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(mode),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: controller.settings.themeMode == mode
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: palette.accent,
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_themeLabel(mode)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await controller.setThemeMode(selected);
    if (!context.mounted) {
      return;
    }
    _showErrorIfAny(context, controller);
  }

  Future<void> _pickDefaultTime(
    BuildContext context,
    SettingsController controller,
  ) async {
    final current = controller.settings.defaultReminderMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Время по умолчанию',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await controller.setDefaultReminderMinutes(
      selected.hour * 60 + selected.minute,
    );
    if (!context.mounted) {
      return;
    }
    _showErrorIfAny(context, controller);
  }

  Future<void> _pickEveningTime(
    BuildContext context,
    SettingsController controller,
  ) async {
    final current = controller.settings.eveningReminderMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: 'Вечернее напоминание',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await controller.setEveningReminderMinutes(
      selected.hour * 60 + selected.minute,
    );
    if (!context.mounted) {
      return;
    }
    _showErrorIfAny(context, controller);
  }

  Future<void> _setReminders(BuildContext context, bool enabled) async {
    final controller = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.setRemindersEnabled(enabled);
    if (!context.mounted) {
      return;
    }
    final error = controller.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      controller.clearError();
    }
  }

  Future<void> _setEveningReminder(BuildContext context, bool enabled) async {
    final controller = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.setEveningReminderEnabled(enabled);
    if (!context.mounted) {
      return;
    }
    final error = controller.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      controller.clearError();
    }
  }

  Future<void> _resetData(BuildContext context) async {
    final palette = context.palette;
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сбросить все данные?'),
        content: const Text(
          'Привычки, история выполнения и настройки напоминаний будут '
          'удалены с устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: palette.danger),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) {
      return;
    }

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Точно сбросить?'),
        content: const Text('Восстановить данные не получится.'),
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
            child: const Text('Сбросить навсегда'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) {
      return;
    }

    final habits = context.read<HabitListController>();
    final settings = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);

    final cleared = await habits.clearAll();
    if (!context.mounted) {
      return;
    }
    if (!cleared) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(habits.errorMessage ?? 'Не удалось сбросить данные.'),
        ),
      );
      habits.clearError();
      return;
    }

    await settings.resetPreferences();
    if (!context.mounted) {
      return;
    }
    final error = settings.errorMessage ?? habits.errorMessage;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      settings.clearError();
      habits.clearError();
      return;
    }

    onDataReset();
    messenger.showSnackBar(const SnackBar(content: Text('Данные сброшены')));
  }

  void _showErrorIfAny(BuildContext context, SettingsController controller) {
    final error = controller.errorMessage;
    if (error == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    controller.clearError();
  }

  static String _themeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => 'Системная',
      AppThemeMode.light => 'Светлая',
      AppThemeMode.dark => 'Тёмная',
    };
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.sm,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) Divider(color: palette.borderSubtle, height: 1),
            children[index],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.icon,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger ? palette.dangerSoft : palette.surfaceSubtle,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: danger ? palette.danger : palette.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    height: 22 / 15,
                    fontWeight: FontWeight.w500,
                    color: danger ? palette.danger : palette.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              value!,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: palette.textSecondary,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ] else if (onTap != null && title != 'Версия') ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return InkWell(onTap: onTap, child: content);
  }
}
