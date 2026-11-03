/// Data pushed to the Android home screen widget.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.completed,
    required this.total,
    required this.pendingNames,
  });

  final int completed;
  final int total;

  /// Names of habits still to do today, in display order.
  final List<String> pendingNames;

  String get progressLabel => total == 0 ? 'Нет привычек' : '$completed из $total';

  String get pendingLabel {
    if (total == 0) {
      return 'Добавьте первую привычку';
    }
    if (pendingNames.isEmpty) {
      return 'Всё выполнено';
    }
    return pendingNames.take(3).join(' · ');
  }
}

/// Platform boundary for the home screen widget.
///
/// Implementations must stay silent when the platform has no widget support;
/// the habit list works the same without it.
abstract interface class HomeWidgetBridge {
  /// Pushes the current snapshot to the widget and redraws it.
  Future<void> push(HomeWidgetSnapshot snapshot);
}

/// Used in tests and on platforms without widgets.
class NoopHomeWidgetBridge implements HomeWidgetBridge {
  const NoopHomeWidgetBridge();

  @override
  Future<void> push(HomeWidgetSnapshot snapshot) async {}
}
