import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:habit_tracker/features/reminders/domain/local_time_zone.dart';

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('known IANA identifiers resolve unchanged', () {
    expect(LocalTimeZone.resolveName('Europe/Moscow'), 'Europe/Moscow');
    expect(LocalTimeZone.resolveName('Asia/Kolkata'), 'Asia/Kolkata');
  });

  test(
    'GMT and UTC aliases resolve instead of falling back to UTC silently',
    () {
      expect(LocalTimeZone.resolveName('GMT'), 'Etc/GMT');
      expect(LocalTimeZone.resolveName('UTC'), 'Etc/UTC');
      expect(LocalTimeZone.isKnown('GMT'), isTrue);
    },
  );

  test('unknown identifiers are reported as unknown', () {
    expect(LocalTimeZone.resolveName('Not/AZone'), isNull);
    expect(LocalTimeZone.resolveName(''), isNull);
    expect(LocalTimeZone.resolveName(null), isNull);
  });

  test('unknown identifier falls back to the device offset', () {
    final location = LocalTimeZone.resolve(
      identifier: 'Not/AZone',
      utcOffset: const Duration(hours: 3),
    );

    expect(location.name, 'UTC+03:00');
    expect(
      tz.TZDateTime(location, 2026, 3, 1, 8, 0).timeZoneOffset,
      const Duration(hours: 3),
    );
  });

  test('fractional and negative offsets are preserved', () {
    final india = LocalTimeZone.fixedOffset(
      const Duration(hours: 5, minutes: 30),
    );
    expect(india.name, 'UTC+05:30');
    expect(
      tz.TZDateTime(india, 2026, 3, 1, 8, 0).timeZoneOffset,
      const Duration(hours: 5, minutes: 30),
    );

    final newYork = LocalTimeZone.fixedOffset(const Duration(hours: -4));
    expect(newYork.name, 'UTC-04:00');
    expect(
      tz.TZDateTime(newYork, 2026, 3, 1, 8, 0).timeZoneOffset,
      const Duration(hours: -4),
    );
  });
}
