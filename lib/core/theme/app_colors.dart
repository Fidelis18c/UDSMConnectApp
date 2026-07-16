import 'package:flutter/material.dart';

/// Brand + adaptive UI colors.
///
/// Text/surface tokens switch with [updateBrightness] (called from
/// [MaterialApp.builder]) so light mode is readable without rewriting every
/// widget call site.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;

  /// Called from [MaterialApp.builder] whenever the active theme changes.
  static void updateBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;

  // ── Brand / status (work in both modes) ───────────────────────────────────
  static const Color primary = Color(0xFF1565C0);

  static const Color statusPending = Color(0xFFE65100);
  static const Color statusReviewed = Color(0xFF2E7D32);
  static const Color statusSubmitted = Color(0xFF1565C0);

  static const Color roleDaruso = Color(0xFF1E88E5);
  static const Color roleCr = Color(0xFF1565C0);
  static const Color roleLecturer = Color(0xFF1976D2);

  static const Color link = Color(0xFF1565C0);
  static const Color chipSelected = Color(0xFF1565C0);
  static const Color fab = Color(0xFF1565C0);

  // ── Adaptive surfaces & text ──────────────────────────────────────────────
  static Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF7F8FA);

  static Color get surface =>
      isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);

  static Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);

  static Color get textSecondary =>
      isDark ? const Color(0xFFBDBDBD) : const Color(0xFF5F6368);

  static Color get textHint =>
      isDark ? const Color(0xFF757575) : const Color(0xFF8A8F98);

  static Color get divider =>
      isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE2E5EA);

  static Color get chipUnselected =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEF1F5);

  static Color get otpBoxSurface =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEF1F5);

  // Fixed dark tokens for dark ThemeData construction (not adaptive getters)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  static const Color darkTextHint = Color(0xFF757575);

  // Fixed light tokens for light ThemeData construction
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF5F6368);
  static const Color lightTextHint = Color(0xFF8A8F98);
}
