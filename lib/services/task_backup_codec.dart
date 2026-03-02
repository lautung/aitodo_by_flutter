import 'dart:convert';

import '../models/task.dart';
import '../models/task_data_bundle.dart';

class TaskBackupCodec {
  static const int currentSchemaVersion = 2;

  Map<String, dynamic> encode({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) {
    return {
      'schemaVersion': currentSchemaVersion,
      'exportTime': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'deletedTasks': deletedTasks.map((t) => t.toJson()).toList(),
    };
  }

  TaskDataBundle decode(String rawContent) {
    final dynamic decoded = json.decode(rawContent);

    if (decoded is List) {
      // 兼容极早期仅导出任务数组的格式。
      final tasks = decoded
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
      return TaskDataBundle(schemaVersion: 0, tasks: tasks);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup content');
    }

    final schemaVersion = _readSchemaVersion(decoded);
    return _migrateToCurrent(decoded, schemaVersion);
  }

  int _readSchemaVersion(Map<String, dynamic> data) {
    final schemaVersion = data['schemaVersion'];
    if (schemaVersion is int) return schemaVersion;

    // 兼容旧格式 version 字段。
    final version = data['version'];
    if (version is int) return 1;

    return 0;
  }

  TaskDataBundle _migrateToCurrent(
    Map<String, dynamic> source,
    int sourceVersion,
  ) {
    if (sourceVersion >= currentSchemaVersion) {
      return TaskDataBundle(
        schemaVersion: sourceVersion,
        tasks: _parseTaskList(source['tasks']),
        deletedTasks: _parseTaskList(source['deletedTasks']),
      );
    }

    // v1: {version, exportTime, tasks}
    if (sourceVersion == 1) {
      return TaskDataBundle(
        schemaVersion: currentSchemaVersion,
        tasks: _parseTaskList(source['tasks']),
        deletedTasks: const [],
      );
    }

    // v0: 尝试从 tasks 字段读取。
    return TaskDataBundle(
      schemaVersion: currentSchemaVersion,
      tasks: _parseTaskList(source['tasks']),
      deletedTasks: const [],
    );
  }

  List<Task> _parseTaskList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

