import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeNotifier() : super(ThemeMode.dark);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'dark';
    value = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }

  bool get isLight => value == ThemeMode.light;
}
