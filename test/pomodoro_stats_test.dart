import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/providers/pomodoro_provider.dart';

void main() {
  group('PomodoroRecord', () {
    test('should serialize to JSON', () {
      final record = PomodoroRecord(
        timestamp: DateTime(2025, 1, 15, 10, 30),
        taskId: 'task-1',
        duration: 1500,
      );

      final json = record.toJson();

      expect(json['timestamp'], '2025-01-15T10:30:00.000');
      expect(json['taskId'], 'task-1');
      expect(json['duration'], 1500);
    });

    test('should deserialize from JSON', () {
      final json = {
        'timestamp': '2025-01-15T10:30:00.000',
        'taskId': 'task-1',
        'duration': 1500,
      };

      final record = PomodoroRecord.fromJson(json);

      expect(record.timestamp.year, 2025);
      expect(record.timestamp.month, 1);
      expect(record.timestamp.day, 15);
      expect(record.taskId, 'task-1');
      expect(record.duration, 1500);
    });

    test('should handle null taskId', () {
      final json = {
        'timestamp': '2025-01-15T10:30:00.000',
        'taskId': null,
        'duration': 1500,
      };

      final record = PomodoroRecord.fromJson(json);

      expect(record.taskId, isNull);
    });
  });

  group('PomodoroProvider statistics', () {
    late PomodoroProvider provider;

    setUp(() {
      provider = PomodoroProvider();
    });

    test('should have default values', () {
      expect(provider.todayPomodoros, 0);
      expect(provider.weekPomodoros, 0);
      expect(provider.monthPomodoros, 0);
      expect(provider.totalPomodoros, 0);
      expect(provider.todayFocusMinutes, 0);
    });

    test('getDailyStats returns correct number of days', () {
      final stats = provider.getDailyStats(7);

      expect(stats.length, 7);
    });

    test('getDailyStats contains DateTime keys', () {
      final stats = provider.getDailyStats(3);

      for (final key in stats.keys) {
        expect(key, isA<DateTime>());
      }
    });

    test('getDailyStats values are integers', () {
      final stats = provider.getDailyStats(3);

      for (final value in stats.values) {
        expect(value, isA<int>());
      }
    });
  });
}
