import 'dart:convert';

import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/services/task_backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskBackupCodec', () {
    final codec = TaskBackupCodec();

    final sampleTask = Task(
      id: 'task-1',
      title: '测试任务',
      createdAt: DateTime(2026, 3, 1, 12),
      reminderTime: DateTime(2026, 3, 1, 11, 45),
      customTagIds: const ['tag-1'],
    );

    test('encode should output schemaVersion 2 payload', () {
      final map = codec.encode(
        tasks: [sampleTask],
        deletedTasks: const [],
      );

      expect(map['schemaVersion'], 2);
      expect((map['tasks'] as List).length, 1);
      expect((map['deletedTasks'] as List).length, 0);
    });

    test('decode should migrate v1 payload to current schema', () {
      final v1Payload = json.encode({
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'tasks': [sampleTask.toJson()],
      });

      final bundle = codec.decode(v1Payload);
      expect(bundle.schemaVersion, TaskBackupCodec.currentSchemaVersion);
      expect(bundle.tasks.length, 1);
      expect(bundle.deletedTasks, isEmpty);
    });

    test('decode should parse v2 payload with deleted tasks', () {
      final v2Payload = json.encode({
        'schemaVersion': 2,
        'exportTime': DateTime.now().toIso8601String(),
        'tasks': [sampleTask.toJson()],
        'deletedTasks': [sampleTask.copyWith(id: 'task-deleted').toJson()],
      });

      final bundle = codec.decode(v2Payload);
      expect(bundle.tasks.length, 1);
      expect(bundle.deletedTasks.length, 1);
      expect(bundle.deletedTasks.first.id, 'task-deleted');
    });
  });
}

