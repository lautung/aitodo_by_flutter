import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';

class TagProvider extends ChangeNotifier {
  List<CustomTag> _tags = [];

  List<CustomTag> get tags => _tags;

  TagProvider() {
    _tags = _getDefaultTags();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = prefs.getString('custom_tags');

    if (tagsJson != null && tagsJson.isNotEmpty) {
      try {
        final List<dynamic> tagsList = json.decode(tagsJson);
        _tags = tagsList
            .map((t) => CustomTag.fromJson(t as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _tags = _getDefaultTags();
      }
    } else {
      _tags = _getDefaultTags();
    }
    notifyListeners();
  }

  List<CustomTag> _getDefaultTags() {
    return [
      CustomTag(id: '1', name: '重要', color: Colors.red),
      CustomTag(id: '2', name: '紧急', color: Colors.orange),
      CustomTag(id: '3', name: '学习', color: Colors.blue),
      CustomTag(id: '4', name: '工作', color: Colors.purple),
      CustomTag(id: '5', name: '生活', color: Colors.green),
    ];
  }

  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsJson = json.encode(_tags.map((t) => t.toJson()).toList());
    await prefs.setString('custom_tags', tagsJson);
  }

  Future<void> addTag(String name, Color color) async {
    final tag = CustomTag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
    _tags.add(tag);
    await _saveTags();
    notifyListeners();
  }

  Future<void> updateTag(String id, String name, Color color) async {
    final index = _tags.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tags[index] = CustomTag(id: id, name: name, color: color);
      await _saveTags();
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    await _saveTags();
    notifyListeners();
  }

  CustomTag? getTagById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}
