/// One habit row shown by the 4×2 widget.
class HomeWidgetItem {
  const HomeWidgetItem({
    required this.name,
    required this.done,
    required this.streak,
    required this.emoji,
  });

  final String name;
  final bool done;
  final int streak;
  final String emoji;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'done': done,
    'streak': streak,
    'emoji': emoji,
  };
}

/// Data pushed to the Android home screen widget.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.completed,
    required this.total,
    required this.pendingNames,
    required this.date,
    this.items = const <HomeWidgetItem>[],
    this.topName,
    this.topStreak = 0,
  });

  final int completed;
  final int total;

  /// Names of habits still to do today, in display order.
  final List<String> pendingNames;

  /// Calendar day (`yyyy-MM-dd`) the snapshot was built for.
  final String date;

  /// First habits of today, at most three, in display order.
  final List<HomeWidgetItem> items;

  /// Habit with the longest current streak, if any.
  final String? topName;
  final int topStreak;

  String get progressLabel =>
      total == 0 ? 'Нет привычек' : '$completed из $total';

  String get pendingLabel {
    if (total == 0) {
      return 'Добавьте первую привычку';
    }
    if (pendingNames.isEmpty) {
      return 'Всё выполнено';
    }
    return pendingNames.take(3).join(' · ');
  }

  /// `empty`, `active`, `done` or `streak`; staleness is added natively by
  /// comparing [date] with the device date.
  String get state {
    if (total == 0) {
      return 'empty';
    }
    if (completed >= total) {
      return 'done';
    }
    if (topStreak >= 7) {
      return 'streak';
    }
    return 'active';
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
