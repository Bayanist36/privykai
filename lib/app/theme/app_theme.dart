import 'package:flutter/material.dart';

import '../app_palette.dart';
import 'app_spacing.dart';

/// Material 3 theme built on the Sukhanov labs design tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      primaryContainer: palette.accentSoft,
      onPrimaryContainer: palette.green700,
      secondary: palette.amber500,
      onSecondary: palette.onAccent,
      secondaryContainer: palette.amber100,
      onSecondaryContainer: palette.amber600,
      tertiary: palette.amber500,
      onTertiary: palette.onAccent,
      surface: palette.background,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      error: palette.danger,
      onError: palette.onAccent,
      errorContainer: palette.dangerSoft,
      onErrorContainer: palette.danger,
      outline: palette.borderStrong,
      outlineVariant: palette.borderSubtle,
      shadow: palette.shadow,
      scrim: const Color(0x6618201B),
      inverseSurface: palette.overlay,
      onInverseSurface: palette.onOverlay,
      inversePrimary: palette.green700,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[palette],
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, palette),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: palette.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 17,
          height: 24 / 17,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.borderStrong,
          disabledForegroundColor: palette.textTertiary,
          textStyle: const TextStyle(
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w600,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: const TextStyle(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: TextStyle(color: palette.textTertiary),
        labelStyle: TextStyle(color: palette.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.overlay,
        contentTextStyle: TextStyle(color: palette.onOverlay),
        actionTextColor: palette.snackAction,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.green700,
        unselectedItemColor: palette.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.accentSoft,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 17,
          height: 24 / 17,
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: palette.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppPalette palette) {
    return base.copyWith(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 44 / 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: palette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: palette.textSecondary,
      ),
    );
  }
}
