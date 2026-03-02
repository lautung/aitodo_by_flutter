import 'dart:convert';
import '../models/task.dart';
import '../models/task_group.dart';

/// 同步数据模型
class SyncData {
  final List<Task> tasks;
  final List<Task> deletedTasks;
  final List<TaskGroup> taskGroups;
  final List<CustomTag> tags;
  final DateTime lastModified;
  final String? deviceId;

  SyncData({
    required this.tasks,
    required this.deletedTasks,
    required this.taskGroups,
    required this.tags,
    required this.lastModified,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'deletedTasks': deletedTasks.map((t) => t.toJson()).toList(),
      'taskGroups': taskGroups.map((g) => g.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      tasks: (json['tasks'] as List?)
          ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      deletedTasks: (json['deletedTasks'] as List?)
          ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      taskGroups: (json['taskGroups'] as List?)
          ?.map((g) => TaskGroup.fromJson(g as Map<String, dynamic>))
          .toList() ?? [],
      tags: (json['tags'] as List?)
          ?.map((t) => CustomTag.fromJson(t as Map<String, dynamic>))
          .toList() ?? [],
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
      deviceId: json['deviceId'] as String?,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory SyncData.fromJsonString(String jsonString) {
    return SyncData.fromJson(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// 创建空数据
  factory SyncData.empty() {
    return SyncData(
      tasks: [],
      deletedTasks: [],
      taskGroups: [],
      tags: [],
      lastModified: DateTime.now(),
    );
  }
}

/// 同步结果
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// 同步结果
class SyncResult {
  final bool success;
  final String? errorMessage;
  final DateTime? timestamp;
  final SyncData? data;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.timestamp,
    this.data,
  });

  factory SyncResult.success({SyncData? data}) {
    return SyncResult(
      success: true,
      timestamp: DateTime.now(),
      data: data,
    );
  }

  factory SyncResult.failure(String errorMessage) {
    return SyncResult(
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }
}

/// 冲突解决策略
enum ConflictStrategy {
  localWins,   // 本地优先
  remoteWins,  // 远程优先
  newerWins,   // 较新的优先
}
