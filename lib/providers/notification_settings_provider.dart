import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  static const String _keyDailySummaryEnabled = 'daily_summary_enabled';
  static const String _keyDailySummaryHour = 'daily_summary_hour';
  static const String _keyDailySummaryMinute = 'daily_summary_minute';

  bool _isDailySummaryEnabled = false;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 20, minute: 0);

  bool get isDailySummaryEnabled => _isDailySummaryEnabled;
  TimeOfDay get dailySummaryTime => _dailySummaryTime;

  NotificationSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDailySummaryEnabled = prefs.getBool(_keyDailySummaryEnabled) ?? false;
    final hour = prefs.getInt(_keyDailySummaryHour) ?? 20;
    final minute = prefs.getInt(_keyDailySummaryMinute) ?? 0;
    _dailySummaryTime = TimeOfDay(hour: hour, minute: minute);
    notifyListeners();
  }

  Future<void> setDailySummaryEnabled(bool enabled) async {
    _isDailySummaryEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailySummaryEnabled, enabled);
    notifyListeners();
  }

  Future<void> setDailySummaryTime(TimeOfDay time) async {
    _dailySummaryTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailySummaryHour, time.hour);
    await prefs.setInt(_keyDailySummaryMinute, time.minute);
    notifyListeners();
  }
}
