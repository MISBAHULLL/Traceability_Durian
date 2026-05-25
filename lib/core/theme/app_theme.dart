import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the global [ThemeData] for the DurianTrace mobile app.
///
/// The typography mirrors the Hanken Grotesk scale defined in the blueprint
/// while falling back to the platform default font so we do not need to ship
/// a custom font asset just to render the home screen.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: const TextTheme(
        // Mirrors `headline-lg` token (24/32, weight 700).
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 32 / 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.24,
          color: AppColors.black,
        ),
        // Mirrors `body-lg` token (16/24, weight 400).
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        // Mirrors `body-md` token (14/20, weight 400).
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        // Mirrors `button` token (16/20, weight 600).
        labelLarge: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.black,
        ),
        // Mirrors `label-bold` token (12/16, weight 700, tracking 0.05em).
        labelSmall: TextStyle(
          fontSize: 10,
          height: 16 / 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.footerCaption,
        ),
      ),
    );
  }
}
