import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/models/task_enums.dart';
import 'package:ai_todo/providers/task_stats.dart';
import 'package:flutter_test/flutter_test.dart';

Task _task({
  required String id,
  required String title,
  bool isCompleted = false,
  TaskCategory category = TaskCategory.other,
  DateTime? completedAt,
  DateTime? dueDate,
}) {
  return Task(
    id: id,
    title: title,
    isCompleted: isCompleted,
    category: category,
    completedAt: completedAt,
    dueDate: dueDate,
    createdAt: DateTime(2026, 3, 1, 9),
  );
}

void main() {
  group('TaskStats', () {
    late List<Task> tasks;

    setUp(() {
      // 创建一些测试任务
      tasks = [
        _task(id: '1', title: '任务1', isCompleted: true, category: TaskCategory.work,
            completedAt: DateTime(2026, 3, 1, 10)),
        _task(id: '2', title: '任务2', isCompleted: true, category: TaskCategory.work,
            completedAt: DateTime(2026, 3, 1, 11)),
        _task(id: '3', title: '任务3', isCompleted: false, category: TaskCategory.life),
        _task(id: '4', title: '任务4', isCompleted: true, category: TaskCategory.study,
            completedAt: DateTime(2026, 3, 2, 9)),
        _task(id: '5', title: '任务5', isCompleted: false, category: TaskCategory.other),
      ];
    });

    test('totalTasks should return correct count', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.totalTasks, 5);
    });

    test('completedTasks should return correct count', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.completedTasks, 3);
    });

    test('activeTasks should return correct count', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.activeTasks, 2);
    });

    test('completionRate should return correct rate', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.completionRate, 0.6); // 3/5 = 0.6
    });

    test('completionRate should return 0 when no tasks', () {
      final stats = TaskStats(
        tasks: [],
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.completionRate, 0.0);
    });

    test('tasksByCategory should return correct counts', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final byCategory = stats.tasksByCategory;
      expect(byCategory[TaskCategory.work], 2);
      expect(byCategory[TaskCategory.life], 1);
      expect(byCategory[TaskCategory.study], 1);
      expect(byCategory[TaskCategory.other], 1);
    });

    test('completedByCategory should return correct counts', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final completed = stats.completedByCategory;
      expect(completed[TaskCategory.work], 2);
      expect(completed[TaskCategory.life], 0);
      expect(completed[TaskCategory.study], 1);
      expect(completed[TaskCategory.other], 0);
    });

    test('getTasksCompletedOn should return tasks completed on specific date', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final completedOnMarch1 = stats.getTasksCompletedOn(DateTime(2026, 3, 1));
      expect(completedOnMarch1.length, 2);
      expect(completedOnMarch1.map((t) => t.id), containsAll(['1', '2']));
    });

    test('getCompletionHeatmapData should return data for past 365 days', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final heatmapData = stats.getCompletionHeatmapData();
      expect(heatmapData.length, 365);
      // 检查有数据的日期
      expect(heatmapData[DateTime(2026, 3, 1)], 2);
      expect(heatmapData[DateTime(2026, 3, 2)], 1);
    });

    test('filteredTasksByTime with all filter should return all tasks', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.filteredTasksByTime.length, 5);
    });

    test('filteredTotalTasks should return correct count', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.filteredTotalTasks, 5);
      expect(stats.filteredCompletedTasks, 3);
      expect(stats.filteredActiveTasks, 2);
    });

    test('filteredCompletionRate should return correct rate', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      expect(stats.filteredCompletionRate, 0.6);
    });

    test('filteredTasksByCategory should work correctly', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final filtered = stats.filteredTasksByCategory;
      expect(filtered[TaskCategory.work], 2);
      expect(filtered[TaskCategory.life], 1);
    });

    test('filteredCompletedByCategory should work correctly', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final filtered = stats.filteredCompletedByCategory;
      expect(filtered[TaskCategory.work], 2);
      expect(filtered[TaskCategory.study], 1);
    });

    test('weeklyCompletionTrend should return list of 7 days', () {
      final stats = TaskStats(
        tasks: tasks,
        deletedTasks: [],
        statsTimeFilter: StatsTimeFilter.all,
      );
      final trend = stats.weeklyCompletionTrend;
      expect(trend.length, 7);
    });
  });
}
