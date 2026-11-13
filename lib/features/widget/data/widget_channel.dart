import 'package:flutter/services.dart';

/// Channel between Flutter and the native home screen widget.
///
/// The widget is rendered by `HabitWidgetProvider` from values stored in the
/// app's shared preferences. This small channel replaces `home_widget` so the
/// release keeps only the permissions it really needs (QA-24-03).
abstract final class WidgetChannel {
  static const MethodChannel instance = MethodChannel(
    'com.sukhanovlabs.habittracker/widget',
  );

  /// Native -> Dart: the user tapped the widget while the app was running.
  static const String tapMethod = 'widgetTap';

  /// Dart -> native: store a new snapshot and redraw the widget.
  static const String updateMethod = 'updateWidget';
}
