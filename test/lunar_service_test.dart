import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/services/lunar_service.dart';

void main() {
  late LunarService lunarService;

  setUp(() {
    lunarService = LunarService();
  });

  group('LunarService Tests', () {
    test('getLunarInfo returns lunar info', () {
      final date = DateTime(2024, 6, 1);
      final info = lunarService.getLunarInfo(date);

      expect(info.lunarYear, isPositive);
      expect(info.lunarMonth, inInclusiveRange(1, 12));
      expect(info.lunarDay, inInclusiveRange(1, 30));
      expect(info.zodiac, isNotEmpty);
      expect(info.monthName, isNotEmpty);
      expect(info.dayName, isNotEmpty);
    });

    test('getLunarInfo returns consistent results for same date', () {
      final date = DateTime(2024, 6, 1);

      final info1 = lunarService.getLunarInfo(date);
      final info2 = lunarService.getLunarInfo(date);

      expect(info1.lunarYear, info2.lunarYear);
      expect(info1.lunarMonth, info2.lunarMonth);
      expect(info1.lunarDay, info2.lunarDay);
      expect(info1.zodiac, info2.zodiac);
    });
  });

  group('HuangliInfo Tests', () {
    test('getHuangliInfo returns valid huangli info', () {
      final date = DateTime(2024, 6, 1);
      final info = lunarService.getHuangliInfo(date);

      expect(info.yi, isNotEmpty);
      expect(info.ji, isNotEmpty);
      expect(info.chong, contains('冲'));
      expect(info.sha, contains('煞'));
      expect(['吉', '平', '凶'], contains(info.luck));
    });

    test('getHuangliInfo returns consistent results for same date', () {
      final date = DateTime(2024, 6, 1);

      final info1 = lunarService.getHuangliInfo(date);
      final info2 = lunarService.getHuangliInfo(date);

      expect(info1.yi, info2.yi);
      expect(info1.ji, info2.ji);
      expect(info1.luck, info2.luck);
    });
  });

  group('LunarService Edge Cases', () {
    test('handles various dates in year', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 3, 15),
        DateTime(2024, 6, 15),
        DateTime(2024, 9, 15),
        DateTime(2024, 12, 31),
      ];

      for (final date in dates) {
        final info = lunarService.getLunarInfo(date);
        expect(info.lunarYear, isPositive);
        expect(info.lunarMonth, inInclusiveRange(1, 12));
        expect(info.lunarDay, inInclusiveRange(1, 30));
        expect(info.zodiac, isNotEmpty);
        expect(info.monthName, isNotEmpty);
        expect(info.dayName, isNotEmpty);
      }
    });

    test('getHuangliInfo works for various dates', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 6, 15),
        DateTime(2024, 12, 31),
      ];

      for (final date in dates) {
        final info = lunarService.getHuangliInfo(date);
        expect(info.yi, isNotEmpty);
        expect(info.ji, isNotEmpty);
        expect(info.chong, isNotEmpty);
        expect(info.sha, isNotEmpty);
        expect(info.luck, isNotEmpty);
      }
    });
  });
}
