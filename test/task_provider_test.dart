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

class _FakeNotificationService implements NotificationService {
  int cancelAllCount = 0;
  final List<String> canceledTaskIds = [];
  final List<String> scheduledTaskIds = [];

  @override
  Future<void> cancelAllReminders() async {
    cancelAllCount++;
  }

  @override
  Future<void> cancelReminder(String taskId) async {
    canceledTaskIds.add(taskId);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleTaskReminder(Task task) async {
    scheduledTaskIds.add(task.id);
  }

  @override
  Future<void> cancelDailySummary() async {}

  @override
  Future<void> scheduleDailySummary(TimeOfDay time, int pendingCount, {List<String>? taskTitles}) async {}

  @override
  Future<void> updateDailySummary(int pendingCount, {List<String>? taskTitles}) async {}
}

Task _task({
  required String id,
  required String title,
  bool isCompleted = false,
  DateTime? dueDate,
  DateTime? reminderTime,
  RepeatType repeatType = RepeatType.none,
}) {
  return Task(
    id: id,
    title: title,
    isCompleted: isCompleted,
    dueDate: dueDate,
    reminderTime: reminderTime,
    repeatType: repeatType,
    createdAt: DateTime(2026, 3, 1, 9),
  );
}

void main() {
  group('TaskProvider behavior', () {
    late _InMemoryTaskRepository repository;
    late _FakeNotificationService notificationService;
    late TaskProvider provider;

    setUp(() async {
      repository = _InMemoryTaskRepository();
      notificationService = _FakeNotificationService();
      provider = TaskProvider(
        taskRepository: repository,
        notificationService: notificationService,
      );
      await provider.initialize();
    });

    test('mergeTasks should upsert by id and reschedule eligible reminders', () async {
      final due = DateTime(2026, 3, 2, 10);
      final reminder = DateTime(2026, 3, 2, 9, 30);

      await provider.replaceAllTasks([
        _task(id: 'a', title: '旧任务A', dueDate: due, reminderTime: reminder),
        _task(id: 'b', title: '任务B'),
      ]);
      notificationService.cancelAllCount = 0;
      notificationService.scheduledTaskIds.clear();

      await provider.mergeTasks([
        _task(id: 'a', title: '新任务A', dueDate: due, reminderTime: reminder),
        _task(
          id: 'c',
          title: '任务C',
          isCompleted: true,
          dueDate: due,
          reminderTime: reminder,
        ),
      ]);

      expect(provider.allTasks.map((t) => t.id).toSet(), {'a', 'b', 'c'});
      expect(provider.getTaskById('a')!.title, '新任务A');
      expect(notificationService.cancelAllCount, 1);
      expect(notificationService.scheduledTaskIds, ['a']);
    });

    test('replaceAllTasks should clear deleted tasks and schedule active reminders', () async {
      final due = DateTime(2026, 3, 2, 10);
      final reminder = DateTime(2026, 3, 2, 9, 30);

      await repository.saveDeletedTasks([
        _task(id: 'trash-1', title: '回收站任务'),
      ]);
      await provider.loadDeletedTasks();

      await provider.replaceAllTasks(
        [
          _task(id: 'r1', title: '需提醒', dueDate: due, reminderTime: reminder),
          _task(
            id: 'r2',
            title: '已完成不提醒',
            isCompleted: true,
            dueDate: due,
            reminderTime: reminder,
          ),
          _task(id: 'r3', title: '无提醒字段'),
        ],
        clearDeletedTasks: true,
      );

      expect(provider.deletedTasks, isEmpty);
      expect(notificationService.cancelAllCount, 1);
      expect(notificationService.scheduledTaskIds, ['r1']);

      final reloadedDeleted = await repository.loadDeletedTasks();
      expect(reloadedDeleted, isEmpty);
    });

    test('deleteTask and restoreTask should move task across recycle bin and reminders', () async {
      final due = DateTime(2026, 3, 2, 10);
      final reminder = DateTime(2026, 3, 2, 9, 30);

      await provider.replaceAllTasks([
        _task(id: 'd1', title: '可恢复任务', dueDate: due, reminderTime: reminder),
      ]);
      notificationService.canceledTaskIds.clear();
      notificationService.scheduledTaskIds.clear();

      await provider.deleteTask('d1');
      expect(provider.getTaskById('d1'), isNull);
      expect(provider.deletedTasks.map((t) => t.id), ['d1']);
      expect(notificationService.canceledTaskIds, ['d1']);

      await provider.restoreTask('d1');
      expect(provider.getTaskById('d1'), isNotNull);
      expect(provider.deletedTasks, isEmpty);
      expect(notificationService.scheduledTaskIds, ['d1']);
    });

    test('toggleTaskCompletion should cancel then reschedule reminder', () async {
      final due = DateTime(2026, 3, 2, 10);
      final reminder = DateTime(2026, 3, 2, 9, 30);

      await provider.replaceAllTasks([
        _task(id: 't1', title: '切换完成状态', dueDate: due, reminderTime: reminder),
      ]);
      notificationService.canceledTaskIds.clear();
      notificationService.scheduledTaskIds.clear();

      await provider.toggleTaskCompletion('t1');
      expect(provider.getTaskById('t1')!.isCompleted, true);
      expect(notificationService.canceledTaskIds, ['t1']);

      await provider.toggleTaskCompletion('t1');
      expect(provider.getTaskById('t1')!.isCompleted, false);
      expect(notificationService.scheduledTaskIds, ['t1']);
    });
  });
}
