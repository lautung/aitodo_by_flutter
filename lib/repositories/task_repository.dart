import '../models/task.dart';
import '../models/task_data_bundle.dart';

abstract class TaskRepository {
  Future<List<Task>> loadTasks();
  Future<void> saveTasks(List<Task> tasks);

  Future<List<Task>> loadDeletedTasks();
  Future<void> saveDeletedTasks(List<Task> tasks);
  Future<void> clearDeletedTasks();

  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  });

  Future<TaskDataBundle?> importTaskBundle(String filePath);
}

