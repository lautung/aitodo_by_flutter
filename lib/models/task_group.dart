import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 任务分组/清单
class TaskGroup {
  final String id;
  final String name;
  final Color color;
  final String? iconName;
  final DateTime createdAt;
  final int sortOrder;

  TaskGroup({
    required this.id,
    required this.name,
    required this.color,
    this.iconName,
    required this.createdAt,
    this.sortOrder = 0,
  });

  TaskGroup copyWith({
    String? id,
    String? name,
    Color? color,
    String? iconName,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return TaskGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      iconName: json['iconName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  static TaskGroup create({
    required String name,
    required Color color,
    String? iconName,
  }) {
    return TaskGroup(
      id: const Uuid().v4(),
      name: name,
      color: color,
      iconName: iconName,
      createdAt: DateTime.now(),
    );
  }
}
