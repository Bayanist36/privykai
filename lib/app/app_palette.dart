import 'package:flutter/material.dart';

import 'theme/app_colors.dart';

/// Every colour the UI needs, resolved per brightness.
///
/// Widgets read it with `context.palette`, so switching the theme does not
/// require rebuilding the design tokens by hand. Light values mirror SUK-4;
/// dark values are a derived companion palette with WCAG AA text contrast.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.green700,
    required this.amber500,
    required this.amber600,
    required this.amber100,
    required this.danger,
    required this.dangerSoft,
    required this.onAccent,
    required this.overlay,
    required this.onOverlay,
    required this.snackAction,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color green700;
  final Color amber500;
  final Color amber600;
  final Color amber100;
  final Color danger;
  final Color dangerSoft;
  final Color onAccent;
  final Color overlay;
  final Color onOverlay;
  final Color snackAction;
  final Color shadow;

  static const AppPalette light = AppPalette(
    background: AppColors.sand25,
    surface: AppColors.white,
    surfaceSubtle: AppColors.sand50,
    borderSubtle: AppColors.sand100,
    borderStrong: AppColors.sand200,
    textPrimary: AppColors.ink900,
    textSecondary: AppColors.ink500,
    textTertiary: AppColors.ink300,
    accent: AppColors.green600,
    accentPressed: AppColors.green700,
    accentSoft: AppColors.green50,
    green700: AppColors.green700,
    amber500: AppColors.amber500,
    amber600: AppColors.amber600,
    amber100: AppColors.amber100,
    danger: AppColors.red600,
    dangerSoft: AppColors.red50,
    onAccent: AppColors.white,
    overlay: AppColors.ink900,
    onOverlay: AppColors.white,
    snackAction: AppColors.green200,
    shadow: Color(0x2E1F5C43),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF101512),
    surface: Color(0xFF1A211C),
    surfaceSubtle: Color(0xFF212A23),
    borderSubtle: Color(0xFF2C362E),
    borderStrong: Color(0xFF3C4A40),
    textPrimary: Color(0xFFEDF2EE),
    textSecondary: Color(0xFFA9B3AC),
    textTertiary: Color(0xFF7A857D),
    accent: Color(0xFF58A985),
    accentPressed: Color(0xFF6DBB97),
    accentSoft: Color(0xFF1E2F26),
    green700: Color(0xFF8CC6A8),
    amber500: Color(0xFFE0A354),
    amber600: Color(0xFFE0A354),
    amber100: Color(0xFF3A2A16),
    danger: Color(0xFFE07A70),
    dangerSoft: Color(0xFF3A211E),
    onAccent: Color(0xFF0D1A13),
    overlay: Color(0xFFE8EFE9),
    onOverlay: Color(0xFF18201B),
    snackAction: Color(0xFF8CC6A8),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? green700,
    Color? amber500,
    Color? amber600,
    Color? amber100,
    Color? danger,
    Color? dangerSoft,
    Color? onAccent,
    Color? overlay,
    Color? onOverlay,
    Color? snackAction,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      green700: green700 ?? this.green700,
      amber500: amber500 ?? this.amber500,
      amber600: amber600 ?? this.amber600,
      amber100: amber100 ?? this.amber100,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      onAccent: onAccent ?? this.onAccent,
      overlay: overlay ?? this.overlay,
      onOverlay: onOverlay ?? this.onOverlay,
      snackAction: snackAction ?? this.snackAction,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) {
      return this;
    }
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      green700: Color.lerp(green700, other.green700, t)!,
      amber500: Color.lerp(amber500, other.amber500, t)!,
      amber600: Color.lerp(amber600, other.amber600, t)!,
      amber100: Color.lerp(amber100, other.amber100, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      onOverlay: Color.lerp(onOverlay, other.onOverlay, t)!,
      snackAction: Color.lerp(snackAction, other.snackAction, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
