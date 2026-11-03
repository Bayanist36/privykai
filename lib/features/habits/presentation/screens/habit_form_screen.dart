import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/core/utils/weekdays.dart';
import 'package:habit_tracker/features/habits/domain/models/habit.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_colors.dart';
import 'package:habit_tracker/features/habits/presentation/constants/habit_icons.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/utils/date_labels.dart';
import 'package:habit_tracker/features/habits/presentation/utils/name_counter.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_scheduler.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';

/// Result returned to the Today screen so it can show the confirmation
/// snackbar after the form is closed.
class HabitFormResult {
  const HabitFormResult(this.message);

  final String message;
}

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({
    this.habit,
    this.initialName,
    this.initialIconKey,
    this.initialColorKey,
    super.key,
  });

  final Habit? habit;
  final String? initialName;
  final String? initialIconKey;
  final String? initialColorKey;

  bool get isEditing => habit != null;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _iconKey;
  late String _colorKey;
  late int _weekdaysMask;
  late bool _reminderEnabled;
  late int _reminderMinutes;
  late int? _reminderIntervalHours;
  late int _reminderWindowEndMinutes;

  late final String _initialName;
  late final String _initialIconKey;
  late final String _initialColorKey;
  late final int _initialWeekdaysMask;
  late final bool _initialReminderEnabled;
  late final int _initialReminderMinutes;
  late final int? _initialReminderIntervalHours;
  late final int _initialReminderWindowEndMinutes;

  static const int _maxMinuteOfDay = 23 * 60 + 59;

  bool _isSaving = false;
  bool _allowPop = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    final settings = context.read<SettingsController>().settings;

    _initialName = habit?.name ?? widget.initialName ?? '';
    _initialIconKey =
        habit?.iconKey ?? widget.initialIconKey ?? HabitIcons.fallbackKey;
    _initialColorKey =
        habit?.colorKey ?? widget.initialColorKey ?? Habit.defaultColorKey;
    _initialWeekdaysMask = habit?.weekdaysMask ?? Weekdays.everyDayMask;
    _initialReminderEnabled = habit?.hasReminder ?? false;
    _initialReminderMinutes =
        habit?.reminderMinutes ?? settings.defaultReminderMinutes;
    _initialReminderIntervalHours = habit?.isIntervalReminder == true
        ? habit?.reminderIntervalHours
        : null;
    _initialReminderWindowEndMinutes =
        habit?.reminderWindowEndMinutes ?? Habit.defaultWindowEndMinutes;

    _nameController = TextEditingController(text: _initialName)
      ..addListener(_onNameChanged);
    _iconKey = _initialIconKey;
    _colorKey = _initialColorKey;
    _weekdaysMask = _initialWeekdaysMask;
    _reminderEnabled = _initialReminderEnabled;
    _reminderMinutes = _initialReminderMinutes;
    _reminderIntervalHours = _initialReminderIntervalHours;
    _reminderWindowEndMinutes = _initialReminderWindowEndMinutes;
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isDirty {
    if (_nameController.text != _initialName ||
        _iconKey != _initialIconKey ||
        _colorKey != _initialColorKey ||
        _weekdaysMask != _initialWeekdaysMask ||
        _reminderEnabled != _initialReminderEnabled) {
      return true;
    }
    return _reminderEnabled &&
        (_reminderMinutes != _initialReminderMinutes ||
            _reminderIntervalHours != _initialReminderIntervalHours ||
            _reminderWindowEndMinutes != _initialReminderWindowEndMinutes);
  }

  bool get _canSave =>
      !_isSaving &&
      _nameController.text.trim().isNotEmpty &&
      Weekdays.isValid(_weekdaysMask);

  Future<void> _onReminderChanged(bool value) async {
    if (!value) {
      setState(() => _reminderEnabled = false);
      return;
    }

    final scheduler = context.read<ReminderScheduler>();
    final messenger = ScaffoldMessenger.of(context);

    final bool alreadyAllowed;
    try {
      alreadyAllowed = await scheduler.areNotificationsEnabled();
    } catch (error) {
      // Plugin initialization can fail (for example, a missing release
      // resource). Keep the switch off and explain the failure instead of
      // crashing or silently ignoring the tap (BUG-02).
      debugPrint('Could not check notification permission: $error');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Не удалось включить напоминание. Попробуйте ещё раз.'),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (alreadyAllowed) {
      setState(() {
        _reminderEnabled = true;
        _permissionDenied = false;
      });
      return;
    }

    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Разрешить уведомления?'),
        content: const Text(
          'Напомним о привычке в выбранное время. Без рекламы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Не сейчас'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Разрешить'),
          ),
        ],
      ),
    );

    if (!mounted || allow != true) {
      return;
    }

    final bool granted;
    try {
      granted = await scheduler.requestPermission();
    } catch (error) {
      debugPrint('Could not request notification permission: $error');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Не удалось включить напоминание. Попробуйте ещё раз.'),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _reminderEnabled = granted;
      _permissionDenied = !granted;
    });
  }

  Future<void> _openNotificationSettings() async {
    await context.read<ReminderScheduler>().openNotificationSettings();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderMinutes ~/ 60,
        minute: _reminderMinutes % 60,
      ),
      helpText: 'Время напоминания',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected != null) {
      setState(() {
        _reminderMinutes = selected.hour * 60 + selected.minute;
        if (_reminderIntervalHours != null) {
          _ensureWindowAfterStart();
        }
      });
    }
  }

  Future<void> _pickWindowEnd() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _reminderWindowEndMinutes ~/ 60,
        minute: _reminderWindowEndMinutes % 60,
      ),
      helpText: 'Напоминать до',
      cancelText: 'Отмена',
      confirmText: 'Готово',
    );
    if (selected == null) {
      return;
    }
    setState(() {
      final value = selected.hour * 60 + selected.minute;
      final next = value <= _reminderMinutes ? _reminderMinutes + 60 : value;
      _reminderWindowEndMinutes = next > _maxMinuteOfDay
          ? _maxMinuteOfDay
          : next;
    });
  }

  void _setReminderInterval(int? hours) {
    setState(() {
      _reminderIntervalHours = hours;
      if (hours != null) {
        _ensureWindowAfterStart();
      }
    });
  }

  void _ensureWindowAfterStart() {
    if (_reminderWindowEndMinutes > _reminderMinutes) {
      return;
    }
    final next = _reminderMinutes + 60;
    _reminderWindowEndMinutes = next > _maxMinuteOfDay ? _maxMinuteOfDay : next;
  }

  Future<bool> _confirmDiscard() async {
    final palette = context.palette;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Выйти без сохранения?'),
        content: const Text('Изменения в этой привычке не сохранятся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Продолжить'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: palette.danger),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_canSave || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final controller = context.read<HabitListController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reminderMinutes = _reminderEnabled ? _reminderMinutes : null;
    final reminderIntervalHours = _reminderEnabled
        ? _reminderIntervalHours
        : null;

    final bool saved;
    if (widget.isEditing) {
      saved = await controller.updateHabit(
        habit: widget.habit!,
        name: _nameController.text,
        iconKey: _iconKey,
        colorKey: _colorKey,
        weekdaysMask: _weekdaysMask,
        reminderMinutes: reminderMinutes,
        reminderIntervalHours: reminderIntervalHours,
        reminderWindowEndMinutes: _reminderWindowEndMinutes,
      );
    } else {
      saved = await controller.addHabit(
        name: _nameController.text,
        iconKey: _iconKey,
        colorKey: _colorKey,
        weekdaysMask: _weekdaysMask,
        reminderMinutes: reminderMinutes,
        reminderIntervalHours: reminderIntervalHours,
        reminderWindowEndMinutes: _reminderWindowEndMinutes,
      );
    }

    if (!mounted) {
      return;
    }

    if (saved) {
      final message = _successMessage(reminderMinutes: reminderMinutes);
      setState(() => _allowPop = true);
      navigator.pop(HabitFormResult(message));
      return;
    }

    setState(() => _isSaving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ?? 'Не удалось сохранить привычку.',
        ),
      ),
    );
    controller.clearError();
  }

  String _successMessage({required int? reminderMinutes}) {
    if (widget.isEditing) {
      return 'Привычка обновлена';
    }
    if (reminderMinutes != null &&
        !Weekdays.includes(_weekdaysMask, DateTime.now())) {
      return 'Привычка добавлена. Первое напоминание: '
          '${Weekdays.nextDayLabel(_weekdaysMask)}';
    }
    return 'Привычка добавлена';
  }

  Future<void> _handlePop(bool didPop) async {
    if (didPop || _isSaving) {
      return;
    }
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await _confirmDiscard();
    if (!mounted || !leave) {
      return;
    }
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final icon = HabitIcons.resolve(_iconKey);
    final color = HabitColors.resolve(_colorKey);

    return PopScope(
      canPop: !_isDirty || _allowPop,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Назад',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.isEditing ? 'Изменить привычку' : 'Новая привычка',
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.xs,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Text('Название', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nameController,
                autofocus: !widget.isEditing,
                maxLength: HabitListController.maxNameLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  hintText: 'Например, пить воду',
                ),
                buildCounter: NameCounter.build,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название привычки';
                  }
                  if (value.trim().runes.length >
                      HabitListController.maxNameLength) {
                    return 'Не длиннее ${HabitListController.maxNameLength} '
                        'символов';
                  }
                  return null;
                },
                // Enter / «Готово» only dismisses the keyboard. Saving is an
                // explicit action so the remaining fields are not skipped.
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SectionLabel(label: 'Иконка', value: icon.label),
              const SizedBox(height: AppSpacing.sm),
              _IconGrid(
                selectedKey: _iconKey,
                onSelected: (key) => setState(() => _iconKey = key),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(label: 'Цвет', value: color.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final option in HabitColors.options)
                    _ColorSwatch(
                      option: option,
                      selected: option.key == _colorKey,
                      onTap: () => setState(() => _colorKey = option.key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(
                label: 'Повторение',
                value: Weekdays.summary(_weekdaysMask),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (
                    var index = 0;
                    index < Weekdays.shortLabels.length;
                    index++
                  )
                    _WeekdayChip(
                      label: Weekdays.shortLabels[index],
                      selected: (_weekdaysMask & (1 << index)) != 0,
                      onTap: () => _toggleWeekday(index),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _ReminderCard(
                enabled: _reminderEnabled,
                minutes: _reminderMinutes,
                intervalHours: _reminderIntervalHours,
                windowEndMinutes: _reminderWindowEndMinutes,
                onToggle: _onReminderChanged,
                onPickTime: _pickTime,
                onPickWindowEnd: _pickWindowEnd,
                onIntervalChanged: _setReminderInterval,
              ),
              if (_permissionDenied) ...[
                const SizedBox(height: AppSpacing.sm),
                _PermissionNotice(onOpenSettings: _openNotificationSettings),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _reminderEnabled && _reminderIntervalHours != null
                          ? 'Напоминание повторяется каждые '
                                '$_reminderIntervalHours ч с '
                                '${DateLabels.reminderTime(_reminderMinutes)} '
                                'до '
                                '${DateLabels.reminderTime(_reminderWindowEndMinutes)} '
                                'в дни по расписанию привычки.'
                          : 'Напоминание приходит один раз в день в выбранные '
                                'дни по расписанию привычки.',
                      style: textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
          child: FilledButton(
            onPressed: _canSave ? _save : null,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.onAccent,
                    ),
                  )
                : Text(widget.isEditing ? 'Сохранить' : 'Создать привычку'),
          ),
        ),
      ),
    );
  }

  void _toggleWeekday(int index) {
    final next = _weekdaysMask ^ (1 << index);
    if (next == 0) {
      return;
    }
    setState(() => _weekdaysMask = next);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.selectedKey, required this.onSelected});

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: HabitIcons.options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final option = HabitIcons.options[index];
        final isSelected = option.key == selectedKey;

        return Semantics(
          button: true,
          selected: isSelected,
          label: option.label,
          child: InkWell(
            onTap: () => onSelected(option.key),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isSelected ? palette.accentSoft : palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? palette.accent : palette.borderSubtle,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  option.glyph,
                  style: const TextStyle(fontSize: 24, height: 1),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final HabitColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? palette.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: option.base,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? palette.accent : palette.surface,
            border: Border.all(
              color: selected ? palette.accent : palette.borderStrong,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: selected ? palette.onAccent : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 20,
            color: palette.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Уведомления отключены в системе',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: palette.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.enabled,
    required this.minutes,
    required this.intervalHours,
    required this.windowEndMinutes,
    required this.onToggle,
    required this.onPickTime,
    required this.onPickWindowEnd,
    required this.onIntervalChanged,
  });

  final bool enabled;
  final int minutes;
  final int? intervalHours;
  final int windowEndMinutes;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final VoidCallback onPickWindowEnd;
  final ValueChanged<int?> onIntervalChanged;

  bool get _isInterval => intervalHours != null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final summary = _isInterval
        ? 'Каждые $intervalHours ч'
        : DateLabels.reminderTime(minutes);

    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(color: palette.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 19,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Напоминание',
                        style: TextStyle(
                          fontSize: 15,
                          height: 22 / 15,
                          fontWeight: FontWeight.w500,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text('В дни по расписанию', style: textTheme.labelSmall),
                    ],
                  ),
                ),
                if (enabled)
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: palette.green700,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                Switch.adaptive(value: enabled, onChanged: onToggle),
              ],
            ),
          ),
          if (enabled) ...[
            Divider(color: palette.borderSubtle, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('Один раз в день'),
                    selected: !_isInterval,
                    onSelected: (_) => onIntervalChanged(null),
                  ),
                  ChoiceChip(
                    label: const Text('Каждые N часов'),
                    selected: _isInterval,
                    onSelected: (_) => onIntervalChanged(intervalHours ?? 2),
                  ),
                ],
              ),
            ),
            if (_isInterval) ...[
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                leading: Icon(
                  Icons.repeat_rounded,
                  color: palette.textSecondary,
                ),
                title: const Text('Повторять каждые'),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: intervalHours,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    items: [
                      for (
                        var hours = Habit.minIntervalHours;
                        hours <= Habit.maxIntervalHours;
                        hours++
                      )
                        DropdownMenuItem<int>(
                          value: hours,
                          child: Text('$hours ч'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onIntervalChanged(value);
                      }
                    },
                  ),
                ),
              ),
              _ReminderTimeRow(
                icon: Icons.play_arrow_rounded,
                title: 'С',
                value: minutes,
                onTap: onPickTime,
              ),
              _ReminderTimeRow(
                icon: Icons.stop_rounded,
                title: 'До',
                value: windowEndMinutes,
                onTap: onPickWindowEnd,
              ),
            ] else
              _ReminderTimeRow(
                icon: Icons.schedule_rounded,
                title: 'Время',
                value: minutes,
                onTap: onPickTime,
              ),
          ],
        ],
      ),
    );
  }
}

class _ReminderTimeRow extends StatelessWidget {
  const _ReminderTimeRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      leading: Icon(icon, color: palette.textSecondary),
      title: Text(title),
      trailing: Text(
        DateLabels.reminderTime(value),
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: palette.green700,
        ),
      ),
      onTap: onTap,
    );
  }
}
