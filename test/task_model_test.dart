import 'package:ai_todo/models/subtask.dart';
import 'package:ai_todo/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task model', () {
    test('toJson/fromJson should keep key fields', () {
      final source = Task(
        id: 'task-1',
        title: '写周报',
        description: '包含本周进展',
        dueDate: DateTime(2026, 3, 5, 18, 0),
        priority: Priority.high,
        category: TaskCategory.work,
        isCompleted: false,
        createdAt: DateTime(2026, 3, 1, 9, 0),
        repeatType: RepeatType.weekly,
        parentId: 'parent-1',
        subtasks: [
          SubTask(id: 'sub-1', title: '收集数据', isCompleted: true),
        ],
        reminderTime: DateTime(2026, 3, 5, 17, 30),
        customTagIds: const ['tag-1', 'tag-2'],
      );

      final restored = Task.fromJson(source.toJson());

      expect(restored.id, source.id);
      expect(restored.title, source.title);
      expect(restored.priority, source.priority);
      expect(restored.category, source.category);
      expect(restored.repeatType, source.repeatType);
      expect(restored.customTagIds, source.customTagIds);
      expect(restored.subtasks.length, 1);
      expect(restored.subtasks.first.title, '收集数据');
    });

    test('copyWith should update fields without mutating source', () {
      final original = Task(
        id: 'task-2',
        title: '原始标题',
        createdAt: DateTime(2026, 3, 1),
      );

      final updated = original.copyWith(
        title: '新标题',
        isCompleted: true,
        completedAt: DateTime(2026, 3, 2),
      );

      expect(original.title, '原始标题');
      expect(original.isCompleted, isFalse);

      expect(updated.title, '新标题');
      expect(updated.isCompleted, isTrue);
      expect(updated.completedAt, isNotNull);
    });
  });
}

