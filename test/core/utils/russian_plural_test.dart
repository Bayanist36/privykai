import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/core/utils/russian_plural.dart';

void main() {
  group('RussianPlural.habits', () {
    test('agrees with 1, 2, 5, 11 and 21', () {
      expect(RussianPlural.habits(1), 'привычка');
      expect(RussianPlural.habits(2), 'привычки');
      expect(RussianPlural.habits(5), 'привычек');
      expect(RussianPlural.habits(11), 'привычек');
      expect(RussianPlural.habits(21), 'привычка');
    });

    test('handles the teens and the remaining units', () {
      expect(RussianPlural.habits(12), 'привычек');
      expect(RussianPlural.habits(14), 'привычек');
      expect(RussianPlural.habits(22), 'привычки');
      expect(RussianPlural.habits(25), 'привычек');
      expect(RussianPlural.habits(0), 'привычек');
    });
  });
}
