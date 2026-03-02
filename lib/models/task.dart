import 'package:flutter/material.dart';
import 'subtask.dart';

/// 重复类型
enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case RepeatType.none:
        return '不重复';
      case RepeatType.daily:
        return '每日';
      case RepeatType.weekly:
        return '每周';
      case RepeatType.monthly:
        return '每月';
      case RepeatType.yearly:
        return '每年';
    }
  }

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepeatType.none,
    );
  }
}

/// 自定义标签
class CustomTag {
  final String id;
  final String name;
  final Color color;

  CustomTag({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
    };
  }

  factory CustomTag.fromJson(Map<String, dynamic> json) {
    return CustomTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }
}

enum Priority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Priority.medium,
    );
  }
}

enum TaskCategory {
  work,
  life,
  study,
  other;

  String get label {
    switch (this) {
      case TaskCategory.work:
        return '工作';
      case TaskCategory.life:
        return '生活';
      case TaskCategory.study:
        return '学习';
      case TaskCategory.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.life:
        return Icons.home;
      case TaskCategory.study:
        return Icons.school;
      case TaskCategory.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.life:
        return Colors.green;
      case TaskCategory.study:
        return Colors.purple;
      case TaskCategory.other:
        return Colors.grey;
    }
  }

  static TaskCategory fromString(String value) {
    return TaskCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskCategory.other,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final Priority priority;
  final TaskCategory category;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final RepeatType repeatType;
  final String? parentId;
  final List<SubTask> subtasks;
  final DateTime? reminderTime;
  final List<String> customTagIds; // 自定义标签ID列表
  final String? groupId; // 任务分组ID

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  bool get isSubtasksCompleted {
    if (subtasks.isEmpty) return isCompleted;
    return subtasks.every((s) => s.isCompleted);
  }

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = Priority.medium,
    this.category = TaskCategory.other,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.repeatType = RepeatType.none,
    this.parentId,
    this.subtasks = const [],
    this.reminderTime,
    this.customTagIds = const [],
    this.groupId,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    TaskCategory? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    RepeatType? repeatType,
    String? parentId,
    List<SubTask>? subtasks,
    DateTime? reminderTime,
    List<String>? customTagIds,
    String? groupId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      repeatType: repeatType ?? this.repeatType,
      parentId: parentId ?? this.parentId,
      subtasks: subtasks ?? this.subtasks,
      reminderTime: reminderTime ?? this.reminderTime,
      customTagIds: customTagIds ?? this.customTagIds,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'category': category.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'repeatType': repeatType.name,
      'parentId': parentId,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'reminderTime': reminderTime?.toIso8601String(),
      'customTagIds': customTagIds,
      'groupId': groupId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    List<SubTask> subtasksList = [];
    if (json['subtasks'] != null) {
      subtasksList = (json['subtasks'] as List)
          .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    List<String> tagIds = [];
    if (json['customTagIds'] != null) {
      tagIds = List<String>.from(json['customTagIds'] as List);
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: Priority.fromString(json['priority'] as String),
      category: TaskCategory.fromString(json['category'] as String),
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      customTagIds: tagIds,
      repeatType: json['repeatType'] != null
          ? RepeatType.fromString(json['repeatType'] as String)
          : RepeatType.none,
      parentId: json['parentId'] as String?,
      subtasks: subtasksList,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      groupId: json['groupId'] as String?,
    );
  }
}
