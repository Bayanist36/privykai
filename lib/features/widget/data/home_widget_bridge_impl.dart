import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'package:habit_tracker/features/widget/domain/home_widget_bridge.dart';

/// Android implementation of the home screen widget bridge.
///
/// The native provider (`HabitWidgetProvider`) reads these keys from the
/// plugin's shared preferences and renders the layout itself.
class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  const HomeWidgetBridgeImpl();

  static const String androidProviderName = 'HabitWidgetProvider';

  static const String completedKey = 'widget_completed';
  static const String totalKey = 'widget_total';
  static const String progressKey = 'widget_progress';
  static const String pendingKey = 'widget_pending';

  @override
  Future<void> push(HomeWidgetSnapshot snapshot) async {
    try {
      await HomeWidget.saveWidgetData<int>(completedKey, snapshot.completed);
      await HomeWidget.saveWidgetData<int>(totalKey, snapshot.total);
      await HomeWidget.saveWidgetData<String>(
        progressKey,
        snapshot.progressLabel,
      );
      await HomeWidget.saveWidgetData<String>(
        pendingKey,
        snapshot.pendingLabel,
      );
      await HomeWidget.updateWidget(
        androidName: androidProviderName,
        qualifiedAndroidName:
            'com.sukhanovlabs.habittracker.$androidProviderName',
      );
    } catch (error) {
      // A widget failure must never break habit edits.
      debugPrint('Could not update the home widget: $error');
    }
  }
}
