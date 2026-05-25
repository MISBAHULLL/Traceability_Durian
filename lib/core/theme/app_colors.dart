import 'package:flutter/material.dart';

/// Centralized color tokens that mirror the DurianTrace design system.
///
/// Values are derived from the DurianTrace AI Development Blueprint
/// and the reference HTML mockup.
class AppColors {
  AppColors._();

  /// Brand primary green (used as MaterialApp seed).
  static const Color primary = Color(0xFF296C11);

  /// Lighter brand green used for the agricultural canvas panel.
  static const Color primaryContainer = Color(0xFF5CA142);

  /// Soft accent green used for input focus rings.
  static const Color primaryFixedDim = Color(0xFF90D972);

  /// Warm off-white used as the global surface background.
  static const Color surface = Color(0xFFFAFAF4);

  /// Pure white used for the welcome header and form fields.
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black for primary text.
  static const Color black = Color(0xFF000000);

  /// Soft gray for placeholder text inside inputs.
  static const Color placeholder = Color(0xFF6B7280);

  /// Slightly darker gray for the welcome subtitle.
  static const Color subtitle = Color(0xFF1F2937);

  /// 60% alpha of #093100, used for the footer disclaimer caption.
  static const Color footerCaption = Color(0x99093100);
}
