import 'package:timezone/timezone.dart' as tz;

/// Resolves the device time zone with an explicit, predictable fallback.
///
/// `flutter_timezone` may return a non-IANA identifier such as `GMT` on some
/// Android builds and emulators. `timezone.getLocation` then throws and the
/// naive fallback is UTC, which silently shifts wall-clock reminders (BUG-06).
/// Resolution order:
///
/// 1. the identifier as-is, if it exists in the timezone database;
/// 2. a known alias (`GMT` → `Etc/GMT`, `UTC` → `Etc/UTC`, …);
/// 3. a fixed-offset location built from `DateTime.now().timeZoneOffset`,
///    so the reminder still fires at the time the user sees.
abstract final class LocalTimeZone {
  static const Map<String, String> aliases = <String, String>{
    'GMT': 'Etc/GMT',
    'UTC': 'Etc/UTC',
    'UT': 'Etc/UTC',
    'Etc/GMT0': 'Etc/GMT',
    'Etc/GMT+0': 'Etc/GMT',
    'Etc/GMT-0': 'Etc/GMT',
    'Etc/Universal': 'Etc/UTC',
    'Universal': 'Etc/UTC',
    'Zulu': 'Etc/UTC',
  };

  /// Canonical database name for [identifier], or `null` when it is unknown.
  static String? resolveName(String? identifier) {
    if (identifier == null) {
      return null;
    }
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final candidates = <String>[
      trimmed,
      if (aliases.containsKey(trimmed)) aliases[trimmed]!,
    ];
    for (final candidate in candidates) {
      if (_exists(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  static bool isKnown(String? identifier) => resolveName(identifier) != null;

  /// Location for [identifier] or a fixed-offset location derived from
  /// [utcOffset]. The returned location is always usable for `zonedSchedule`.
  static tz.Location resolve({
    required String? identifier,
    required Duration utcOffset,
  }) {
    final name = resolveName(identifier);
    if (name != null) {
      return tz.getLocation(name);
    }
    return fixedOffset(utcOffset);
  }

  /// Fixed-offset location named `UTC+HH:MM` / `UTC-HH:MM`.
  ///
  /// Used only when the platform identifier is not in the timezone database.
  /// Unlike silently choosing UTC, this preserves the device's wall-clock
  /// offset (including half-hour and 45-minute zones).
  static tz.Location fixedOffset(Duration utcOffset) {
    final normalized = Duration(minutes: utcOffset.inMinutes);
    final absolute = normalized.abs();
    final hours = absolute.inHours.toString().padLeft(2, '0');
    final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    final sign = normalized.isNegative ? '-' : '+';

    return tz.Location(
      'UTC$sign$hours:$minutes',
      <int>[tz.minTime],
      const <int>[0],
      <tz.TimeZone>[tz.TimeZone(normalized, isDst: false, abbreviation: '')],
    );
  }

  static bool _exists(String name) {
    try {
      tz.getLocation(name);
      return true;
    } on tz.LocationNotFoundException {
      return false;
    }
  }
}
