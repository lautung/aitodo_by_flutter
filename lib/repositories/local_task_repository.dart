import '../models/task.dart';
import '../models/task_data_bundle.dart';
import '../services/storage_service.dart';
import 'task_repository.dart';

class LocalTaskRepository implements TaskRepository {
  final StorageService _storageService;

  LocalTaskRepository({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService();

  @override
  Future<List<Task>> loadTasks() => _storageService.loadTasks();

  @override
  Future<void> saveTasks(List<Task> tasks) => _storageService.saveTasks(tasks);

  @override
  Future<List<Task>> loadDeletedTasks() => _storageService.loadDeletedTasks();

  @override
  Future<void> saveDeletedTasks(List<Task> tasks) =>
      _storageService.saveDeletedTasks(tasks);

  @override
  Future<void> clearDeletedTasks() => _storageService.clearDeletedTasks();

  @override
  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) {
    return _storageService.exportTaskBundle(
      tasks: tasks,
      deletedTasks: deletedTasks,
    );
  }

  @override
  Future<TaskDataBundle?> importTaskBundle(String filePath) {
    return _storageService.importTaskBundle(filePath);
  }
}

