// Reference implementation of the design tokens for Flutter.
// Copy to lib/theme/app_theme.dart. Values mirror design-tokens.json.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const sand25 = Color(0xFFFAF8F3);
  static const sand50 = Color(0xFFF4F1E9);
  static const sand100 = Color(0xFFEAE5DA);
  static const sand200 = Color(0xFFDCD5C6);
  static const sand300 = Color(0xFFC4BCAA);
  static const ink900 = Color(0xFF18201B);
  static const ink700 = Color(0xFF3C463F);
  static const ink500 = Color(0xFF6B756D);
  static const ink300 = Color(0xFFA9B0AA);

  static const green700 = Color(0xFF1F5C43);
  static const green600 = Color(0xFF2A7052);
  static const green500 = Color(0xFF3B8A68);
  static const green200 = Color(0xFFBFD9CB);
  static const green100 = Color(0xFFDCEBE1);
  static const green50 = Color(0xFFEDF4EF);

  static const amber800 = Color(0xFF8A4F13);
  static const amber600 = Color(0xFFB87120);
  static const amber500 = Color(0xFFD98A2B);
  static const amber100 = Color(0xFFF8E9D2);
  static const red600 = Color(0xFFB23B32);
  static const red50 = Color(0xFFFBECEA);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

abstract final class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static final pill = BorderRadius.circular(999);
}

abstract final class AppSizes {
  static const screenPadding = 20.0;
  static const touchTarget = 48.0;
  static const buttonHeight = 52.0;
  static const inputHeight = 56.0;
  static const habitCardMinHeight = 72.0;
  static const habitIcon = 40.0;
  static const habitCheckIndicator = 28.0;
  static const emojiTileHeight = 52.0;
  static const weekdayChip = 40.0;
  static const tabbarHeight = 76.0;
  static const fabSize = 56.0;
  static const contentMaxWidth = 560.0;
}

abstract final class AppText {
  static const display = TextStyle(
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.ink900,
  );
  static const h1 = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.ink900,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.ink900,
  );
  static const h3 = TextStyle(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.ink900,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink900,
  );
  static const bodyStrong = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.ink900,
  );
  static const bodySmall = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink900,
  );
  static const label = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.ink500,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.ink500,
  );
  static const button = TextStyle(
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  static const stat = TextStyle(
    fontSize: 36,
    height: 40 / 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.white,
  );
  static const tab = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w500,
    color: AppColors.ink500,
  );
}

abstract final class AppTheme {
  static const _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.green600,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.green50,
    onPrimaryContainer: AppColors.green700,
    secondary: AppColors.amber500,
    onSecondary: AppColors.ink900,
    secondaryContainer: AppColors.amber100,
    onSecondaryContainer: AppColors.amber800,
    error: AppColors.red600,
    onError: AppColors.white,
    errorContainer: AppColors.red50,
    onErrorContainer: AppColors.red600,
    surface: AppColors.sand25,
    onSurface: AppColors.ink900,
    surfaceContainerHighest: AppColors.sand100,
    onSurfaceVariant: AppColors.ink500,
    outline: AppColors.sand200,
    outlineVariant: AppColors.sand100,
  );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: AppColors.sand25,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: AppText.display,
        headlineMedium: AppText.h1,
        titleLarge: AppText.h2,
        titleMedium: AppText.h3,
        bodyLarge: AppText.body,
        bodyMedium: AppText.bodySmall,
        labelLarge: AppText.button,
        labelMedium: AppText.label,
        labelSmall: AppText.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sand25,
        foregroundColor: AppColors.ink900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.h3,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green600,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.sand100,
          disabledForegroundColor: AppColors.ink300,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppText.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppText.body.copyWith(color: AppColors.ink300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.sand200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.sand200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.green600),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.red600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.sand100,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink900,
        contentTextStyle: AppText.bodySmall.copyWith(color: AppColors.white),
        actionTextColor: AppColors.green200,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.green700,
        unselectedItemColor: AppColors.ink500,
        selectedLabelStyle: AppText.tab,
        unselectedLabelStyle: AppText.tab,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

enum HabitEmoji {
  water('💧', 'Вода'),
  run('🏃', 'Бег'),
  workout('💪', 'Тренировка'),
  reading('📖', 'Чтение'),
  sleep('😴', 'Сон'),
  meditation('🧘', 'Медитация'),
  walk('🚶', 'Прогулка'),
  food('🥗', 'Питание'),
  teeth('🦷', 'Зубы'),
  morning('☀️', 'Утро'),
  vitamins('💊', 'Витамины'),
  journal('✍️', 'Дневник'),
  music('🎸', 'Музыка'),
  cleaning('🧹', 'Уборка'),
  quit('🚭', 'Отказ'),
  other('🌱', 'Другое');

  const HabitEmoji(this.glyph, this.label);
  final String glyph;
  final String label;
}

enum HabitColor {
  green(Color(0xFF2A7052), Color(0xFFE4EFE8), 'Зелёный'),
  blue(Color(0xFF3C6E9F), Color(0xFFE6EEF6), 'Синий'),
  amber(Color(0xFFB87120), Color(0xFFF8E9D2), 'Янтарный'),
  coral(Color(0xFFB45A4A), Color(0xFFF7E4DF), 'Коралловый'),
  violet(Color(0xFF6B5B95), Color(0xFFECE8F4), 'Фиолетовый'),
  teal(Color(0xFF2F7C77), Color(0xFFE1F0EE), 'Бирюзовый');

  const HabitColor(this.base, this.soft, this.label);
  final Color base;
  final Color soft;
  final String label;
}

/// Битовая маска дней недели: Пн = 1 << 0 ... Вс = 1 << 6.
const int kEveryDayMask = 0x7F;
