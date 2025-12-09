// lib/core/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const _kKey = 'app_theme_mode';

  // ValueNotifier so UI can listen for changes
  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  ThemeService._internal();
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;

  /// Call during app init (await) to load persisted value.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    switch (raw) {
      case 'light':
        mode.value = ThemeMode.light;
        break;
      case 'dark':
        mode.value = ThemeMode.dark;
        break;
      default:
        mode.value = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    final s = m == ThemeMode.system ? 'system' : (m == ThemeMode.dark ? 'dark' : 'light');
    await prefs.setString(_kKey, s);
  }

  ThemeMode get current => mode.value;
}
