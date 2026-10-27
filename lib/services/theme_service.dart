import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'user_theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? themeStr = prefs.getString(_themeKey);
      if (themeStr != null) {
        themeModeNotifier.value = _parseThemeMode(themeStr);
      }
    } catch (_) {}
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (_) {}
  }

  static ThemeMode _parseThemeMode(String name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
