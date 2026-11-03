import 'package:flutter/material.dart';

/// Color palette from the design system (design/styles/design-system.css).
abstract final class AppColors {
  static const Color sand25 = Color(0xFFFAF8F3);
  static const Color sand50 = Color(0xFFF4F1E9);
  static const Color sand100 = Color(0xFFEAE5DA);
  static const Color sand200 = Color(0xFFDCD5C6);
  static const Color sand300 = Color(0xFFC4BCAA);

  static const Color ink900 = Color(0xFF18201B);
  static const Color ink700 = Color(0xFF3C463F);
  static const Color ink500 = Color(0xFF6B756D);
  static const Color ink300 = Color(0xFFA9B0AA);

  static const Color green700 = Color(0xFF1F5C43);
  static const Color green600 = Color(0xFF2A7052);
  static const Color green500 = Color(0xFF3B8A68);
  static const Color green200 = Color(0xFFBFD9CB);
  static const Color green100 = Color(0xFFDCEBE1);
  static const Color green50 = Color(0xFFEDF4EF);

  static const Color amber800 = Color(0xFF8A4F13);
  static const Color amber600 = Color(0xFFB87120);
  static const Color amber500 = Color(0xFFD98A2B);
  static const Color amber100 = Color(0xFFF8E9D2);

  static const Color red600 = Color(0xFFB23B32);
  static const Color red50 = Color(0xFFFBECEA);

  static const Color white = Color(0xFFFFFFFF);

  static const Color background = sand25;
  static const Color surface = white;
  static const Color surfaceSubtle = sand50;
  static const Color borderSubtle = sand100;
  static const Color borderStrong = sand200;

  static const Color textPrimary = ink900;
  static const Color textSecondary = ink500;
  static const Color textTertiary = ink300;

  static const Color accent = green600;
  static const Color accentPressed = green700;
  static const Color accentSoft = green50;
  static const Color streak = amber500;
  static const Color danger = red600;
}
