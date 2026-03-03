import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/models/task.dart';

void main() {
  group('CustomRepeat', () {
    // Tests already exist in custom_repeat_test.dart
  });

  group('Task with sortOrder', () {
    test('should have default sortOrder of 0', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      expect(task.sortOrder, 0);
    });

    test('should accept custom sortOrder', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
        sortOrder: 5,
      );

      expect(task.sortOrder, 5);
    });

    test('should copyWith sortOrder', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      final updatedTask = task.copyWith(sortOrder: 10);

      expect(updatedTask.sortOrder, 10);
      expect(task.sortOrder, 0); // Original unchanged
    });

    test('should serialize sortOrder to JSON', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
        sortOrder: 15,
      );

      final json = task.toJson();

      expect(json['sortOrder'], 15);
    });

    test('should deserialize sortOrder from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': '1',
        'title': 'Test Task',
        'createdAt': now.toIso8601String(),
        'isCompleted': false,
        'priority': 'medium',
        'category': 'other',
        'sortOrder': 20,
      };

      final task = Task.fromJson(json);

      expect(task.sortOrder, 20);
    });
  });

  group('Task with reminderMinutesBefore', () {
    test('should have empty reminderMinutesBefore by default', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      expect(task.reminderMinutesBefore, isEmpty);
    });

    test('should accept custom reminderMinutesBefore', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
        reminderMinutesBefore: [1440, 60, 15], // 1 day, 1 hour, 15 minutes
      );

      expect(task.reminderMinutesBefore, [1440, 60, 15]);
    });

    test('should copyWith reminderMinutesBefore', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
      );

      final updatedTask = task.copyWith(reminderMinutesBefore: [30, 10]);

      expect(updatedTask.reminderMinutesBefore, [30, 10]);
    });

    test('should serialize reminderMinutesBefore to JSON', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime.now(),
        reminderMinutesBefore: [60, 15],
      );

      final json = task.toJson();

      expect(json['reminderMinutesBefore'], [60, 15]);
    });

    test('should deserialize reminderMinutesBefore from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': '1',
        'title': 'Test Task',
        'createdAt': now.toIso8601String(),
        'isCompleted': false,
        'priority': 'medium',
        'category': 'other',
        'reminderMinutesBefore': [120, 30, 5],
      };

      final task = Task.fromJson(json);

      expect(task.reminderMinutesBefore, [120, 30, 5]);
    });
  });
}
