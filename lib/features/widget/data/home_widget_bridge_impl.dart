import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:habit_tracker/features/widget/data/widget_channel.dart';
import 'package:habit_tracker/features/widget/domain/home_widget_bridge.dart';

/// Android implementation of the home screen widget bridge.
///
/// Writes the snapshot through the native `WidgetChannel`; the native provider
/// (`HabitWidgetProvider`) reads the same keys from the app's shared
/// preferences and renders the layout itself.
class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  const HomeWidgetBridgeImpl();

  static const String completedKey = 'widget_completed';
  static const String totalKey = 'widget_total';
  static const String progressKey = 'widget_progress';
  static const String pendingKey = 'widget_pending';
  static const String dateKey = 'widget_date';
  static const String stateKey = 'widget_state';
  static const String itemsKey = 'widget_items_json';
  static const String topNameKey = 'widget_top_name';
  static const String topStreakKey = 'widget_top_streak';

  @override
  Future<void> push(HomeWidgetSnapshot snapshot) async {
    try {
      await WidgetChannel.instance.invokeMethod<void>(
        WidgetChannel.updateMethod,
        <String, Object?>{
          completedKey: snapshot.completed,
          totalKey: snapshot.total,
          progressKey: snapshot.progressLabel,
          pendingKey: snapshot.pendingLabel,
          dateKey: snapshot.date,
          stateKey: snapshot.state,
          itemsKey: jsonEncode(<Map<String, Object?>>[
            for (final item in snapshot.items) item.toJson(),
          ]),
          topNameKey: snapshot.topName ?? '',
          topStreakKey: snapshot.topStreak,
        },
      );
    } catch (error) {
      // A widget failure must never break habit edits.
      debugPrint('Could not update the home widget: $error');
    }
  }
}
