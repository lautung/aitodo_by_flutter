import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/models/task_data_bundle.dart';
import 'package:ai_todo/providers/task_provider.dart';
import 'package:ai_todo/repositories/task_repository.dart';
import 'package:ai_todo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemoryTaskRepository implements TaskRepository {
  List<Task> _tasks = [];
  List<Task> _deletedTasks = [];

  @override
  Future<void> clearDeletedTasks() async => _deletedTasks = [];

  @override
  Future<String?> exportTaskBundle({
    required List<Task> tasks,
    required List<Task> deletedTasks,
  }) async => 'mock://backup.json';

  @override
  Future<TaskDataBundle?> importTaskBundle(String filePath) async =>
      TaskDataBundle(schemaVersion: 2, tasks: _tasks, deletedTasks: _deletedTasks);

  @override
  Future<List<Task>> loadDeletedTasks() async => _deletedTasks;

  @override
  Future<List<Task>> loadTasks() async => _tasks;

  @override
  Future<void> saveDeletedTasks(List<Task> tasks) async =>
      _deletedTasks = List<Task>.from(tasks);

  @override
  Future<void> saveTasks(List<Task> tasks) async =>
      _tasks = List<Task>.from(tasks);
}

class _FakeNotificationService implements NotificationService {
  @override
  Future<void> cancelAllReminders() async {}

  @override
  Future<void> cancelReminder(String taskId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleTaskReminder(Task task) async {}

  @override
  Future<void> cancelDailySummary() async {}

  @override
  Future<void> scheduleDailySummary(TimeOfDay time, int pendingCount, {List<String>? taskTitles}) async {}

  @override
  Future<void> updateDailySummary(int pendingCount, {List<String>? taskTitles}) async {}
}

Task _createTask({
  required String id,
  required String title,
  bool isCompleted = false,
  List<String> prerequisiteIds = const [],
}) {
  return Task(
    id: id,
    title: title,
    isCompleted: isCompleted,
    prerequisiteIds: prerequisiteIds,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Task Dependencies', () {
    late TaskProvider provider;

    setUp(() async {
      final repository = _InMemoryTaskRepository();
      final notificationService = _FakeNotificationService();
      provider = TaskProvider(
        taskRepository: repository,
        notificationService: notificationService,
      );
      await provider.initialize();
    });

    test('canCompleteTask returns true when no prerequisites', () async {
      final task = _createTask(id: '1', title: 'Task 1');
      await provider.addTask(title: task.title);

      expect(provider.canCompleteTask(provider.allTasks.first.id), true);
    });

    test('canCompleteTask returns false when prerequisite not completed', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(
        id: '2',
        title: 'Task 2',
        prerequisiteIds: ['1'],
      );

      await provider.addTask(title: task1.title);
      await provider.addTask(
        title: task2.title,
        customTagIds: [],
        prerequisiteIds: [provider.allTasks.first.id],
      );

      final task2Id = provider.allTasks.last.id;
      expect(provider.canCompleteTask(task2Id), false);
    });

    test('canCompleteTask returns true when all prerequisites completed', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(
        id: '2',
        title: 'Task 2',
        prerequisiteIds: ['1'],
      );

      await provider.addTask(title: task1.title);
      final task1Id = provider.allTasks.first.id;
      await provider.addTask(title: task2.title, prerequisiteIds: [task1Id]);

      // 先完成前置任务
      await provider.toggleTaskCompletion(task1Id);

      final task2Id = provider.allTasks.last.id;
      expect(provider.canCompleteTask(task2Id), true);
    });

    test('getPrerequisiteTasks returns correct list', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(id: '2', title: 'Task 2');

      await provider.addTask(title: task1.title);
      await provider.addTask(title: task2.title);

      final task1Id = provider.allTasks[0].id;
      final task2Id = provider.allTasks[1].id;

      // 更新 task2 的前置任务
      final updatedTask2 = provider.allTasks[1].copyWith(
        prerequisiteIds: [task1Id],
      );
      await provider.updateTask(updatedTask2);

      final prereqs = provider.getPrerequisiteTasks(task2Id);
      expect(prereqs.length, 1);
      expect(prereqs.first.title, task1.title);
    });

    test('getDependentTasks returns correct list', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(id: '2', title: 'Task 2');

      await provider.addTask(title: task1.title);
      await provider.addTask(title: task2.title);

      final task1Id = provider.allTasks[0].id;
      final task2Id = provider.allTasks[1].id;

      // 更新 task2 的前置任务
      final updatedTask2 = provider.allTasks[1].copyWith(
        prerequisiteIds: [task1Id],
      );
      await provider.updateTask(updatedTask2);

      final dependents = provider.getDependentTasks(task1Id);
      expect(dependents.length, 1);
      expect(dependents.first.title, task2.title);
    });

    test('toggleTaskCompletion fails when prerequisites not met', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(
        id: '2',
        title: 'Task 2',
        prerequisiteIds: ['1'],
      );

      await provider.addTask(title: task1.title);
      final task1Id = provider.allTasks.first.id;
      await provider.addTask(title: task2.title, prerequisiteIds: [task1Id]);

      final task2Id = provider.allTasks.last.id;
      final result = await provider.toggleTaskCompletion(task2Id);

      expect(result, false);
      // task2 应该仍然是未完成状态
      expect(provider.getTaskById(task2Id)?.isCompleted, false);
    });

    test('toggleTaskCompletion succeeds when prerequisites met', () async {
      final task1 = _createTask(id: '1', title: 'Task 1');
      final task2 = _createTask(
        id: '2',
        title: 'Task 2',
        prerequisiteIds: ['1'],
      );

      await provider.addTask(title: task1.title);
      final task1Id = provider.allTasks.first.id;
      await provider.addTask(title: task2.title, prerequisiteIds: [task1Id]);

      // 先完成前置任务
      await provider.toggleTaskCompletion(task1Id);

      final task2Id = provider.allTasks.last.id;
      final result = await provider.toggleTaskCompletion(task2Id);

      expect(result, true);
      expect(provider.getTaskById(task2Id)?.isCompleted, true);
    });
  });
}
