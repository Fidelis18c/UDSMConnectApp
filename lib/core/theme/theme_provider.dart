import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to dark mode as requested, or system if preferred.
    return ThemeMode.dark;
  }

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
