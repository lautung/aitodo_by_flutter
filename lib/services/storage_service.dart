import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_data_bundle.dart';
import 'task_backup_codec.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _deletedTasksKey = 'deleted_tasks';
  final TaskBackupCodec _backupCodec = TaskBackupCodec();

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);

    if (tasksJson == null || tasksJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> tasksList = json.decode(tasksJson);
      return tasksList
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = json.encode(
      tasks.map((task) => task.toJson()).toList(),
    );
    await prefs.setString(_tasksKey, tasksJson);
  }

  /// 导出任务到JSON文件
  Future<String?> exportTasks(List<Task> tasks) async {
    final bundlePath = await exportTaskBundle(
      tasks: tasks,
      deletedTasks: const [],
    );
    return bundlePath;
  }

  /// 导出完整备份（任务 + 回收站）
  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/aitodo_backup_$timestamp.json');

      final exportData = _backupCodec.encode(
        tasks: tasks,
        deletedTasks: deletedTasks,
      );

      await file.writeAsString(json.encode(exportData));
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// 从JSON文件导入任务
  Future<List<Task>?> importTasks(String filePath) async {
    final bundle = await importTaskBundle(filePath);
    return bundle?.tasks;
  }

  /// 从JSON文件导入完整备份
  Future<TaskDataBundle?> importTaskBundle(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      return _backupCodec.decode(content);
    } catch (e) {
      return null;
    }
  }

  /// 保存已删除的任务（用于回收站）
  Future<void> saveDeletedTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksJson = json.encode(
      tasks.map((task) => task.toJson()).toList(),
    );
    await prefs.setString(_deletedTasksKey, tasksJson);
  }

  /// 加载已删除的任务
  Future<List<Task>> loadDeletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_deletedTasksKey);

    if (tasksJson == null || tasksJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> tasksList = json.decode(tasksJson);
      return tasksList
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 清空回收站
  Future<void> clearDeletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deletedTasksKey);
  }
}
