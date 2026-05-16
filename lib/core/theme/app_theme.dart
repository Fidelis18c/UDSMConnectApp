import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_shapes.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: AppTypography.getTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.buttonBorderRadius,
          ),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: Colors.white30, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: Colors.white30, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        selectedItemColor: AppColors.primary, // Using primary blue, no gold
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.fabBorderRadius,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: Color(0xFFF5F5F5),
        background: Colors.white,
      ),
      textTheme: AppTypography.getTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppShapes.buttonBorderRadius,
          ),
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        hintStyle: const TextStyle(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: Colors.black12, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: Colors.black12, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.fabBorderRadius,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF333333),
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
