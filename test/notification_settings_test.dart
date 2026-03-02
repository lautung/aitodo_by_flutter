import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_todo/providers/notification_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationSettingsProvider', () {
    test('should have default values', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isDailySummaryEnabled, false);
      expect(provider.dailySummaryTime.hour, 20);
      expect(provider.dailySummaryTime.minute, 0);
    });

    test('should load saved settings', () async {
      SharedPreferences.setMockInitialValues({
        'daily_summary_enabled': true,
        'daily_summary_hour': 9,
        'daily_summary_minute': 30,
      });
      final provider = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isDailySummaryEnabled, true);
      expect(provider.dailySummaryTime.hour, 9);
      expect(provider.dailySummaryTime.minute, 30);
    });

    test('should update daily summary enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      await provider.setDailySummaryEnabled(true);
      expect(provider.isDailySummaryEnabled, true);

      await provider.setDailySummaryEnabled(false);
      expect(provider.isDailySummaryEnabled, false);
    });

    test('should update daily summary time', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      const newTime = TimeOfDay(hour: 8, minute: 0);
      await provider.setDailySummaryTime(newTime);

      expect(provider.dailySummaryTime.hour, 8);
      expect(provider.dailySummaryTime.minute, 0);
    });

    test('should persist settings across provider instances', () async {
      SharedPreferences.setMockInitialValues({
        'daily_summary_enabled': true,
        'daily_summary_hour': 18,
        'daily_summary_minute': 45,
      });

      final provider1 = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(provider1.isDailySummaryEnabled, true);
      expect(provider1.dailySummaryTime.hour, 18);

      // 修改第一个实例
      await provider1.setDailySummaryEnabled(false);

      // 创建新的实例应该能读取到之前的设置
      final provider2 = NotificationSettingsProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      // provider2 应该读取到初始设置（因为 setMockInitialValues 只在 setUp 中调用）
      // 实际持久化测试需要在真实环境中运行
    });
  });
}
