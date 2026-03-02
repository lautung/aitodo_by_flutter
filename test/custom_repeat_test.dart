import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/models/task.dart';

void main() {
  group('CustomRepeat', () {
    test('should create CustomRepeat with interval and unit', () {
      final customRepeat = CustomRepeat(
        interval: 3,
        unit: RepeatUnit.day,
      );

      expect(customRepeat.interval, 3);
      expect(customRepeat.unit, RepeatUnit.day);
    });

    test('should create CustomRepeat with end date', () {
      final endDate = DateTime(2025, 12, 31);
      final customRepeat = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.week,
        endDate: endDate,
      );

      expect(customRepeat.endDate, endDate);
    });

    test('should create CustomRepeat with repeat count limit', () {
      final customRepeat = CustomRepeat(
        interval: 1,
        unit: RepeatUnit.month,
        endAfterNTimes: 10,
      );

      expect(customRepeat.endAfterNTimes, 10);
    });

    test('description returns correct format for days', () {
      final customRepeat = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.day,
      );

      expect(customRepeat.description, '每2天');
    });

    test('description returns correct format for single interval', () {
      final customRepeat = CustomRepeat(
        interval: 1,
        unit: RepeatUnit.day,
      );

      expect(customRepeat.description, '每天');
    });

    test('description returns correct format for weeks', () {
      final customRepeat = CustomRepeat(
        interval: 3,
        unit: RepeatUnit.week,
      );

      expect(customRepeat.description, '每3周');
    });

    test('description returns correct format for months', () {
      final customRepeat = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.month,
      );

      expect(customRepeat.description, '每2月');
    });

    test('getNextDate returns correct date for days', () {
      final customRepeat = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.day,
      );
      final currentDate = DateTime(2025, 1, 15);

      final nextDate = customRepeat.getNextDate(currentDate);

      expect(nextDate, DateTime(2025, 1, 17));
    });

    test('getNextDate returns correct date for weeks', () {
      final customRepeat = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.week,
      );
      final currentDate = DateTime(2025, 1, 15);

      final nextDate = customRepeat.getNextDate(currentDate);

      expect(nextDate, DateTime(2025, 1, 29));
    });

    test('getNextDate returns correct date for months', () {
      final customRepeat = CustomRepeat(
        interval: 1,
        unit: RepeatUnit.month,
      );
      final currentDate = DateTime(2025, 1, 15);

      final nextDate = customRepeat.getNextDate(currentDate);

      expect(nextDate, DateTime(2025, 2, 15));
    });

    test('getNextDate handles month end correctly', () {
      final customRepeat = CustomRepeat(
        interval: 1,
        unit: RepeatUnit.month,
      );
      final currentDate = DateTime(2025, 1, 31);

      final nextDate = customRepeat.getNextDate(currentDate);

      // 2月没有31日，应该回退到28日
      expect(nextDate?.day, lessThanOrEqualTo(28));
      expect(nextDate?.month, 2);
    });

    test('toJson and fromJson work correctly', () {
      final customRepeat = CustomRepeat(
        interval: 3,
        unit: RepeatUnit.week,
        endAfterNTimes: 5,
        endDate: DateTime(2025, 12, 31),
      );

      final json = customRepeat.toJson();
      final restored = CustomRepeat.fromJson(json);

      expect(restored.interval, customRepeat.interval);
      expect(restored.unit, customRepeat.unit);
      expect(restored.endAfterNTimes, customRepeat.endAfterNTimes);
      expect(restored.endDate?.year, customRepeat.endDate?.year);
      expect(restored.endDate?.month, customRepeat.endDate?.month);
      expect(restored.endDate?.day, customRepeat.endDate?.day);
    });

    test('copyWith creates new instance with updated values', () {
      final original = CustomRepeat(
        interval: 1,
        unit: RepeatUnit.day,
      );

      final updated = original.copyWith(
        interval: 5,
        unit: RepeatUnit.month,
      );

      expect(updated.interval, 5);
      expect(updated.unit, RepeatUnit.month);
      // original should be unchanged
      expect(original.interval, 1);
      expect(original.unit, RepeatUnit.day);
    });
  });

  group('RepeatUnit', () {
    test('fromString returns correct unit', () {
      expect(RepeatUnit.fromString('day'), RepeatUnit.day);
      expect(RepeatUnit.fromString('week'), RepeatUnit.week);
      expect(RepeatUnit.fromString('month'), RepeatUnit.month);
    });

    test('fromString returns default for invalid value', () {
      expect(RepeatUnit.fromString('invalid'), RepeatUnit.day);
    });

    test('label returns correct Chinese text', () {
      expect(RepeatUnit.day.label, '天');
      expect(RepeatUnit.week.label, '周');
      expect(RepeatUnit.month.label, '月');
    });
  });

  group('RepeatType with custom', () {
    test('custom has correct label', () {
      expect(RepeatType.custom.label, '自定义');
    });

    test('fromString handles custom', () {
      expect(RepeatType.fromString('custom'), RepeatType.custom);
    });
  });
}
