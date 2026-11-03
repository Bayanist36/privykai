import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/data/models/habit_adapter.dart';
import 'package:habit_tracker/features/settings/data/models/app_settings_adapter.dart';

void main() {
  test('Hive adapter typeIds stay outside the reserved 0-12 range', () {
    // Hive's FrameValueType enum owns 0-12; a custom adapter in that range is
    // read back as a built-in type instead of our document (BUG-01/BUG-04).
    final ids = <int>[
      HabitAdapter.habitTypeId,
      AppSettingsAdapter.settingsTypeId,
    ];

    for (final id in ids) {
      expect(
        id,
        greaterThanOrEqualTo(13),
        reason: 'typeId $id collides with Hive built-in frame values',
      );
    }
    expect(ids.toSet(), hasLength(ids.length));
    expect(HabitAdapter.habitTypeId, 13);
    expect(AppSettingsAdapter.settingsTypeId, 14);
  });
}
