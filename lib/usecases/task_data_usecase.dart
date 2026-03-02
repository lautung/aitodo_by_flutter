import '../models/task.dart';
import '../models/task_data_bundle.dart';
import '../repositories/task_repository.dart';

class TaskDataUseCase {
  final TaskRepository _repository;

  TaskDataUseCase(this._repository);

  Future<TaskDataBundle> initialize() async {
    final tasks = await _repository.loadTasks();
    final deletedTasks = await _repository.loadDeletedTasks();
    return TaskDataBundle(
      schemaVersion: 2,
      tasks: tasks,
      deletedTasks: deletedTasks,
    );
  }

  Future<void> persistTasks(List<Task> tasks) => _repository.saveTasks(tasks);

  Future<void> persistDeletedTasks(List<Task> deletedTasks) =>
      _repository.saveDeletedTasks(deletedTasks);

  Future<void> clearDeletedTasks() => _repository.clearDeletedTasks();

  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) {
    return _repository.exportTaskBundle(
      tasks: tasks,
      deletedTasks: deletedTasks,
    );
  }

  Future<TaskDataBundle?> importTaskBundle(String filePath) =>
      _repository.importTaskBundle(filePath);
}

