import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/features/habits/presentation/controllers/habit_list_controller.dart';
import 'package:habit_tracker/features/habits/presentation/screens/habits_screen.dart';
import 'package:habit_tracker/features/reminders/domain/reminder_plan.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';
import 'package:habit_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:habit_tracker/features/statistics/presentation/screens/statistics_screen.dart';

/// Bottom navigation shell: Сегодня · Статистика · Настройки.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool? _remindersEnabled;
  EveningReminder? _eveningReminder;

  void _goToday() => setState(() => _index = 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncReminders();
    }
  }

  void _syncReminders() {
    final controller = context.read<HabitListController>();
    controller.syncReminders(enabled: _remindersEnabled ?? true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final remindersEnabled = context.select(
      (SettingsController settings) => settings.settings.remindersEnabled,
    );
    if (_remindersEnabled != remindersEnabled) {
      _remindersEnabled = remindersEnabled;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncReminders();
        }
      });
    }

    final eveningReminder = context
        .select<SettingsController, EveningReminder?>(
          (settings) => settings.settings.eveningReminderEnabled
              ? EveningReminder(
                  minutes: settings.settings.eveningReminderMinutes,
                )
              : null,
        );
    if (_eveningReminder != eveningReminder) {
      _eveningReminder = eveningReminder;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HabitListController>().setEveningReminder(
            eveningReminder,
          );
        }
      });
    }

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          _goToday();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const HabitsScreen(),
            const StatisticsScreen(),
            SettingsScreen(onDataReset: _goToday),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.borderSubtle)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (index) => setState(() => _index = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.today_outlined),
                activeIcon: Icon(Icons.today_rounded),
                label: 'Сегодня',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Статистика',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'Настройки',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
