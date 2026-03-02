import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/models/task_data_bundle.dart';
import 'package:ai_todo/repositories/task_repository.dart';
import 'package:ai_todo/usecases/task_data_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryTaskRepository implements TaskRepository {
  List<Task> _tasks = [];
  List<Task> _deletedTasks = [];

  @override
  Future<void> clearDeletedTasks() async {
    _deletedTasks = [];
  }

  @override
  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) async {
    return 'mock://backup.json';
  }

  @override
  Future<TaskDataBundle?> importTaskBundle(String filePath) async {
    if (filePath != 'mock://backup.json') return null;
    return TaskDataBundle(
      schemaVersion: 2,
      tasks: _tasks,
      deletedTasks: _deletedTasks,
    );
  }

  @override
  Future<List<Task>> loadDeletedTasks() async => _deletedTasks;

  @override
  Future<List<Task>> loadTasks() async => _tasks;

  @override
  Future<void> saveDeletedTasks(List<Task> tasks) async {
    _deletedTasks = List<Task>.from(tasks);
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _tasks = List<Task>.from(tasks);
  }
}

void main() {
  group('TaskDataUseCase', () {
    late _InMemoryTaskRepository repository;
    late TaskDataUseCase useCase;

    setUp(() {
      repository = _InMemoryTaskRepository();
      useCase = TaskDataUseCase(repository);
    });

    test('initialize should return tasks and deleted tasks', () async {
      final task = Task(
        id: 'task-1',
        title: '任务1',
        createdAt: DateTime(2026, 3, 1),
      );
      final deletedTask = Task(
        id: 'task-2',
        title: '任务2',
        createdAt: DateTime(2026, 3, 1),
      );

      await repository.saveTasks([task]);
      await repository.saveDeletedTasks([deletedTask]);

      final bundle = await useCase.initialize();
      expect(bundle.tasks.length, 1);
      expect(bundle.deletedTasks.length, 1);
      expect(bundle.tasks.first.id, 'task-1');
      expect(bundle.deletedTasks.first.id, 'task-2');
    });

    test('export/import should delegate to repository', () async {
      final exportedPath = await useCase.exportTaskBundle(
        tasks: const [],
        deletedTasks: const [],
      );
      expect(exportedPath, 'mock://backup.json');

      final imported = await useCase.importTaskBundle('mock://backup.json');
      expect(imported, isNotNull);
      expect(imported!.schemaVersion, 2);
    });
  });
}

