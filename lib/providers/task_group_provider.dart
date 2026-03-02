import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_group.dart';

class TaskGroupProvider extends ChangeNotifier {
  List<TaskGroup> _groups = [];
  String? _selectedGroupId;

  List<TaskGroup> get groups => List.unmodifiable(_groups);
  String? get selectedGroupId => _selectedGroupId;
  TaskGroup? get selectedGroup => _selectedGroupId != null
      ? _groups.firstWhere(
          (g) => g.id == _selectedGroupId,
          orElse: () => _groups.first,
        )
      : null;

  static const String _storageKey = 'task_groups';

  Future<void> initialize() async {
    await _loadGroups();
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getStringList(_storageKey) ?? [];
    _groups = groupsJson
        .map((jsonString) {
          try {
            return TaskGroup.fromJson(jsonDecode(jsonString));
          } catch (e) {
            return null;
          }
        })
        .where((g) => g != null)
        .cast<TaskGroup>()
        .toList();
    notifyListeners();
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = _groups.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_storageKey, groupsJson);
  }

  Future<void> addGroup(TaskGroup group) async {
    _groups.add(group);
    await _saveGroups();
    notifyListeners();
  }

  Future<void> updateGroup(TaskGroup group) async {
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      await _saveGroups();
      notifyListeners();
    }
  }

  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    if (_selectedGroupId == groupId) {
      _selectedGroupId = null;
    }
    await _saveGroups();
    notifyListeners();
  }

  void selectGroup(String? groupId) {
    _selectedGroupId = groupId;
    notifyListeners();
  }

  TaskGroup? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }
}
