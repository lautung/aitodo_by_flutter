import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

/// 自定义优先级
class CustomPriority {
  final String id;
  final String name;
  final Color color;
  final int level; // 数值越高优先级越高

  CustomPriority({
    required this.id,
    required this.name,
    required this.color,
    required this.level,
  });

  /// 转换为内置Priority枚举
  Priority toPriority() {
    switch (id) {
      case 'high':
        return Priority.high;
      case 'medium':
        return Priority.medium;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'level': level,
    };
  }

  factory CustomPriority.fromJson(Map<String, dynamic> json) {
    return CustomPriority(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      level: json['level'] as int,
    );
  }
}

class PriorityProvider extends ChangeNotifier {
  List<CustomPriority> _customPriorities = [];

  List<CustomPriority> get customPriorities => _customPriorities;

  /// 获取所有优先级（包括内置的）
  List<CustomPriority> get allPriorities {
    return [
      CustomPriority(id: 'high', name: '高', color: Colors.red, level: 3),
      CustomPriority(id: 'medium', name: '中', color: Colors.orange, level: 2),
      CustomPriority(id: 'low', name: '低', color: Colors.green, level: 1),
      ..._customPriorities,
    ];
  }

  PriorityProvider() {
    _loadPriorities();
  }

  Future<void> _loadPriorities() async {
    final prefs = await SharedPreferences.getInstance();
    final prioritiesJson = prefs.getString('custom_priorities');

    if (prioritiesJson != null && prioritiesJson.isNotEmpty) {
      try {
        final List<dynamic> prioritiesList = json.decode(prioritiesJson);
        _customPriorities = prioritiesList
            .map((p) => CustomPriority.fromJson(p as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _customPriorities = [];
      }
    }
    notifyListeners();
  }

  Future<void> _savePriorities() async {
    final prefs = await SharedPreferences.getInstance();
    final prioritiesJson = json.encode(_customPriorities.map((p) => p.toJson()).toList());
    await prefs.setString('custom_priorities', prioritiesJson);
  }

  Future<void> addPriority(String name, Color color, int level) async {
    final priority = CustomPriority(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
      level: level,
    );
    _customPriorities.add(priority);
    await _savePriorities();
    notifyListeners();
  }

  Future<void> updatePriority(String id, String name, Color color, int level) async {
    final index = _customPriorities.indexWhere((p) => p.id == id);
    if (index != -1) {
      _customPriorities[index] = CustomPriority(
        id: id,
        name: name,
        color: color,
        level: level,
      );
      await _savePriorities();
      notifyListeners();
    }
  }

  Future<void> deletePriority(String id) async {
    _customPriorities.removeWhere((p) => p.id == id);
    await _savePriorities();
    notifyListeners();
  }

  CustomPriority? getPriorityById(String id) {
    // 先查找自定义优先级
    try {
      return _customPriorities.firstWhere((p) => p.id == id);
    } catch (e) {
      // 再查找内置优先级
      switch (id) {
        case 'high':
          return CustomPriority(id: 'high', name: '高', color: Colors.red, level: 3);
        case 'medium':
          return CustomPriority(id: 'medium', name: '中', color: Colors.orange, level: 2);
        case 'low':
          return CustomPriority(id: 'low', name: '低', color: Colors.green, level: 1);
        default:
          return null;
      }
    }
  }

  /// 从Priority转换到CustomPriority
  CustomPriority fromPriority(Priority priority) {
    switch (priority) {
      case Priority.high:
        return CustomPriority(id: 'high', name: '高', color: Colors.red, level: 3);
      case Priority.medium:
        return CustomPriority(id: 'medium', name: '中', color: Colors.orange, level: 2);
      case Priority.low:
        return CustomPriority(id: 'low', name: '低', color: Colors.green, level: 1);
    }
  }
}
