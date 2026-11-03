/// Russian plural forms for habit streak labels.
abstract final class RussianPlural {
  static String days(int value) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 14) {
      return 'дней';
    }
    return switch (value % 10) {
      1 => 'день',
      2 || 3 || 4 => 'дня',
      _ => 'дней',
    };
  }

  static String streak(int value) {
    if (value <= 0) {
      return 'Серия начнётся сегодня';
    }
    return '$value ${days(value)} подряд';
  }

  static String habits(int value) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 14) {
      return 'привычек';
    }
    return switch (value % 10) {
      1 => 'привычка',
      2 || 3 || 4 => 'привычки',
      _ => 'привычек',
    };
  }

  static String symbols(int value) {
    final mod100 = value % 100;
    if (mod100 >= 11 && mod100 <= 14) {
      return 'символов';
    }
    return switch (value % 10) {
      1 => 'символ',
      2 || 3 || 4 => 'символа',
      _ => 'символов',
    };
  }

  /// Text for the remaining-characters counter.
  ///
  /// Flutter's built-in Russian localisation hardcodes the "one" form as
  /// "Остался 1 символ", which is also selected for 21, 31, ... (BUG-12).
  /// Building the string ourselves keeps the number and the noun in agreement.
  static String remainingCharacters(int value) {
    final noun = symbols(value);
    final verb = noun == 'символ' ? 'Остался' : 'Осталось';
    return '$verb $value $noun';
  }
}
