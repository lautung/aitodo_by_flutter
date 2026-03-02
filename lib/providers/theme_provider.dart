import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF2196F3);

  static const List<Color> availableColors = [
    Color(0xFF2196F3), // 蓝色
    Color(0xFF4CAF50), // 绿色
    Color(0xFFFF9800), // 橙色
    Color(0xFF9C27B0), // 紫色
    Color(0xFFE91E63), // 粉色
    Color(0xFF00BCD4), // 青色
    Color(0xFFFF5722), // 深橙
    Color(0xFF607D8B), // 灰蓝
  ];

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
