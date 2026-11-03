/// Weekday scheduling helpers.
///
/// A schedule is a bit mask where Monday is bit 0 and Sunday is bit 6, so the
/// seven-day week is `1 << 7 - 1 == 0x7F`. The representation is persisted as
/// an integer in Hive and stays stable across locales.
abstract final class Weekdays {
  static const int everyDayMask = 0x7F;

  static const List<String> shortLabels = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];

  static const List<String> fullLabels = <String>[
    'понедельник',
    'вторник',
    'среду',
    'четверг',
    'пятницу',
    'субботу',
    'воскресенье',
  ];

  static int bitFor(DateTime date) => 1 << (date.weekday - 1);

  static bool isEveryDay(int mask) => mask == everyDayMask;

  static bool includes(int mask, DateTime date) => (mask & bitFor(date)) != 0;

  static bool isValid(int mask) => mask > 0 && (mask & ~everyDayMask) == 0;

  /// «Каждый день» or «Пн, Ср, Пт».
  static String summary(int mask) {
    if (isEveryDay(mask)) {
      return 'Каждый день';
    }
    final selected = <String>[
      for (var index = 0; index < shortLabels.length; index++)
        if ((mask & (1 << index)) != 0) shortLabels[index],
    ];
    return selected.isEmpty ? 'Не выбрано' : selected.join(', ');
  }

  /// Human-readable label of the next scheduled weekday, including today.
  static String nextDayLabel(int mask, {DateTime? from}) {
    final start = _dateOnly(from ?? DateTime.now());
    for (var offset = 0; offset < 7; offset++) {
      final candidate = DateTime(start.year, start.month, start.day + offset);
      if (includes(mask, candidate)) {
        final label = offset == 0
            ? 'сегодня'
            : fullLabels[candidate.weekday - 1];
        return label;
      }
    }
    return fullLabels.first;
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
