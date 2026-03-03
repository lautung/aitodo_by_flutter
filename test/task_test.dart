import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/models/subtask.dart';

void main() {
  group('Task Model Tests', () {
    test('Task creation with required fields', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.isCompleted, false);
      expect(task.priority, Priority.medium);
      expect(task.category, TaskCategory.other);
    });

    test('Task copyWith creates new instance with updated fields', () {
      final task = Task(
        id: '1',
        title: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = task.copyWith(
        title: 'Updated',
        priority: Priority.high,
      );

      expect(updated.title, 'Updated');
      expect(updated.priority, Priority.high);
      expect(updated.id, '1'); // unchanged
      expect(task.title, 'Original'); // original unchanged
    });

    test('Task toJson and fromJson roundtrip', () {
      final original = Task(
        id: '1',
        title: 'Test Task',
        description: 'Description',
        dueDate: DateTime(2024, 12, 31),
        priority: Priority.high,
        category: TaskCategory.work,
        isCompleted: true,
        createdAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 6, 15),
        repeatType: RepeatType.daily,
      );

      final json = original.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.priority, original.priority);
      expect(restored.category, original.category);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.repeatType, original.repeatType);
    });

    test('subtaskProgress calculates correctly', () {
      final task = Task(
        id: '1',
        title: 'Parent Task',
        createdAt: DateTime(2024, 1, 1),
        subtasks: [
          SubTask(id: '1', title: 'Sub 1', isCompleted: true),
          SubTask(id: '2', title: 'Sub 2', isCompleted: true),
          SubTask(id: '3', title: 'Sub 3', isCompleted: false),
          SubTask(id: '4', title: 'Sub 4', isCompleted: false),
        ],
      );

      expect(task.subtaskProgress, 0.5);
    });

    test('isSubtasksCompleted returns correctly', () {
      final incompleteTask = Task(
        id: '1',
        title: 'Task',
        createdAt: DateTime(2024, 1, 1),
        isCompleted: true,
        subtasks: [
          SubTask(id: '1', title: 'Sub 1', isCompleted: true),
          SubTask(id: '2', title: 'Sub 2', isCompleted: false),
        ],
      );

      final completeTask = Task(
        id: '2',
        title: 'Task',
        createdAt: DateTime(2024, 1, 1),
        isCompleted: false,
        subtasks: [
          SubTask(id: '1', title: 'Sub 1', isCompleted: true),
          SubTask(id: '2', title: 'Sub 2', isCompleted: true),
        ],
      );

      expect(incompleteTask.isSubtasksCompleted, false);
      expect(completeTask.isSubtasksCompleted, true);
    });

    test('Task with no subtasks uses isCompleted directly', () {
      final task = Task(
        id: '1',
        title: 'Task',
        createdAt: DateTime(2024, 1, 1),
        isCompleted: true,
      );

      expect(task.isSubtasksCompleted, true);
    });
  });

  group('Priority Tests', () {
    test('Priority label returns correct Chinese', () {
      expect(Priority.high.label, '高');
      expect(Priority.medium.label, '中');
      expect(Priority.low.label, '低');
    });

    test('Priority color returns correct colors', () {
      expect(Priority.high.color, Colors.red);
      expect(Priority.medium.color, Colors.orange);
      expect(Priority.low.color, Colors.green);
    });

    test('Priority fromString parses correctly', () {
      expect(Priority.fromString('high'), Priority.high);
      expect(Priority.fromString('medium'), Priority.medium);
      expect(Priority.fromString('low'), Priority.low);
      expect(Priority.fromString('invalid'), Priority.medium); // default
    });
  });

  group('TaskCategory Tests', () {
    test('TaskCategory label returns correct Chinese', () {
      expect(TaskCategory.work.label, '工作');
      expect(TaskCategory.life.label, '生活');
      expect(TaskCategory.study.label, '学习');
      expect(TaskCategory.other.label, '其他');
    });

    test('TaskCategory icon returns correct icons', () {
      expect(TaskCategory.work.icon, Icons.work);
      expect(TaskCategory.life.icon, Icons.home);
      expect(TaskCategory.study.icon, Icons.school);
      expect(TaskCategory.other.icon, Icons.more_horiz);
    });

    test('TaskCategory fromString parses correctly', () {
      expect(TaskCategory.fromString('work'), TaskCategory.work);
      expect(TaskCategory.fromString('life'), TaskCategory.life);
      expect(TaskCategory.fromString('invalid'), TaskCategory.other); // default
    });
  });

  group('RepeatType Tests', () {
    test('RepeatType label returns correct Chinese', () {
      expect(RepeatType.none.label, '不重复');
      expect(RepeatType.daily.label, '每日');
      expect(RepeatType.weekly.label, '每周');
      expect(RepeatType.monthly.label, '每月');
      expect(RepeatType.yearly.label, '每年');
      expect(RepeatType.custom.label, '自定义');
    });

    test('RepeatType fromString parses correctly', () {
      expect(RepeatType.fromString('daily'), RepeatType.daily);
      expect(RepeatType.fromString('weekly'), RepeatType.weekly);
      expect(RepeatType.fromString('invalid'), RepeatType.none); // default
    });
  });

  group('CustomRepeat Tests', () {
    test('CustomRepeat description generates correctly', () {
      final repeat1 = CustomRepeat(interval: 1, unit: RepeatUnit.day);
      // interval of 1 might show as "每天"
      expect(repeat1.description, anyOf('每1天', '每天'));

      final repeat2 = CustomRepeat(interval: 2, unit: RepeatUnit.week);
      expect(repeat2.description, '每2周');

      final repeat3 = CustomRepeat(interval: 3, unit: RepeatUnit.month);
      expect(repeat3.description, '每3月');
    });

    test('CustomRepeat getNextDate calculates correctly', () {
      final repeat = CustomRepeat(interval: 1, unit: RepeatUnit.day);
      final date = DateTime(2024, 1, 1);
      final next = repeat.getNextDate(date);

      expect(next, DateTime(2024, 1, 2));
    });

    test('CustomRepeat toJson and fromJson roundtrip', () {
      final original = CustomRepeat(
        interval: 2,
        unit: RepeatUnit.week,
        endAfterNTimes: 5,
        endDate: DateTime(2024, 12, 31),
      );

      final json = original.toJson();
      final restored = CustomRepeat.fromJson(json);

      expect(restored.interval, original.interval);
      expect(restored.unit, original.unit);
      expect(restored.endAfterNTimes, original.endAfterNTimes);
    });
  });

  group('CustomTag Tests', () {
    test('CustomTag toJson and fromJson roundtrip', () {
      final original = CustomTag(
        id: 'tag1',
        name: 'Important',
        color: Colors.red,
      );

      final json = original.toJson();
      final restored = CustomTag.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.color.toARGB32(), original.color.toARGB32());
    });
  });
}
