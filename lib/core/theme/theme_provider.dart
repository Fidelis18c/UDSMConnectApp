import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePrefsKey = 'udsm_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load saved preference asynchronously; default dark until loaded.
    Future.microtask(_restore);
    return ThemeMode.dark;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_themePrefsKey);
      if (raw == 'light') {
        state = ThemeMode.light;
      } else if (raw == 'dark') {
        state = ThemeMode.dark;
      } else if (raw == 'system') {
        state = ThemeMode.system;
      }
    } catch (_) {
      // Keep default dark
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_themePrefsKey, value);
    } catch (_) {
      // Preference write failed — in-memory mode still applies this session
    }
  }

  Future<void> toggleTheme() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
