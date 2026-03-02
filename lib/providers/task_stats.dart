import '../models/task.dart';
import '../models/task_enums.dart';

/// 任务统计数据提供者
class TaskStats {
  final List<Task> tasks;
  final List<Task> deletedTasks;
  final StatsTimeFilter statsTimeFilter;
  final DateTime? customStatsStartDate;
  final DateTime? customStatsEndDate;

  TaskStats({
    required this.tasks,
    required this.deletedTasks,
    required this.statsTimeFilter,
    this.customStatsStartDate,
    this.customStatsEndDate,
  });

  /// 总任务数
  int get totalTasks => tasks.length;

  /// 已完成任务数
  int get completedTasks => tasks.where((t) => t.isCompleted).length;

  /// 活跃任务数
  int get activeTasks => tasks.where((t) => !t.isCompleted).length;

  /// 完成率
  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  /// 按分类统计任务数
  Map<TaskCategory, int> get tasksByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = tasks.where((t) => t.category == category).length;
    }
    return result;
  }

  /// 按分类统计已完成任务数
  Map<TaskCategory, int> get completedByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = tasks
          .where((t) => t.category == category && t.isCompleted)
          .length;
    }
    return result;
  }

  /// 获取一年内每天完成任务数量的热力图数据
  Map<DateTime, int> getCompletionHeatmapData() {
    final Map<DateTime, int> result = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 过去 365 天
    for (int i = 364; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = tasks
          .where((t) =>
              t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(dayStart) &&
              t.completedAt!.isBefore(dayEnd))
          .length;

      result[dayStart] = count;
    }

    return result;
  }

  /// 获取指定月份的任务按日期分布
  Map<DateTime, int> getTasksByMonth(int year, int month) {
    final Map<DateTime, int> result = {};
    final monthEnd = DateTime(year, month + 1, 0);

    for (int day = 1; day <= monthEnd.day; day++) {
      final date = DateTime(year, month, day);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completedCount = tasks
          .where((t) =>
              t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(dayStart) &&
              t.completedAt!.isBefore(dayEnd))
          .length;

      result[dayStart] = completedCount;
    }

    return result;
  }

  /// 获取指定日期完成的任务列表
  List<Task> getTasksCompletedOn(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return tasks
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(dayStart) &&
            t.completedAt!.isBefore(dayEnd))
        .toList();
  }

  /// 周完成趋势（最近7天）
  List<int> get weeklyCompletionTrend {
    final List<int> result = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = tasks
          .where((t) =>
              t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(dayStart) &&
              t.completedAt!.isBefore(dayEnd))
          .length;
      result.add(count);
    }
    return result;
  }

  /// 根据时间过滤获取任务列表
  List<Task> get filteredTasksByTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (statsTimeFilter) {
      case StatsTimeFilter.all:
        return tasks;
      case StatsTimeFilter.year:
        final yearStart = DateTime(now.year, 1, 1);
        return tasks.where((t) => t.createdAt.isAfter(yearStart)).toList();
      case StatsTimeFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return tasks.where((t) => t.createdAt.isAfter(monthStart)).toList();
      case StatsTimeFilter.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return tasks.where((t) => t.createdAt.isAfter(weekStart)).toList();
      case StatsTimeFilter.today:
        final dayStart = today;
        final dayEnd = today.add(const Duration(days: 1));
        return tasks.where((t) =>
            t.createdAt.isAfter(dayStart) && t.createdAt.isBefore(dayEnd)).toList();
      case StatsTimeFilter.custom:
        if (customStatsStartDate == null || customStatsEndDate == null) {
          return tasks;
        }
        final startDate = DateTime(
          customStatsStartDate!.year,
          customStatsStartDate!.month,
          customStatsStartDate!.day,
        );
        final endDate = DateTime(
          customStatsEndDate!.year,
          customStatsEndDate!.month,
          customStatsEndDate!.day,
        ).add(const Duration(days: 1));
        return tasks.where((t) =>
            t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate)).toList();
    }
  }

  // Filtered statistics getters
  int get filteredTotalTasks => filteredTasksByTime.length;
  int get filteredCompletedTasks =>
      filteredTasksByTime.where((t) => t.isCompleted).length;
  int get filteredActiveTasks =>
      filteredTasksByTime.where((t) => !t.isCompleted).length;
  double get filteredCompletionRate =>
      filteredTotalTasks > 0 ? filteredCompletedTasks / filteredTotalTasks : 0.0;

  Map<TaskCategory, int> get filteredTasksByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] =
          filteredTasksByTime.where((t) => t.category == category).length;
    }
    return result;
  }

  Map<TaskCategory, int> get filteredCompletedByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = filteredTasksByTime
          .where((t) => t.category == category && t.isCompleted)
          .length;
    }
    return result;
  }

  List<int> get filteredWeeklyCompletionTrend {
    final List<int> result = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final tasksInRange = filteredTasksByTime.where((t) {
        if (statsTimeFilter != StatsTimeFilter.all) {
          return t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(dayStart) &&
              t.completedAt!.isBefore(dayEnd);
        }
        return t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(dayStart) &&
            t.completedAt!.isBefore(dayEnd);
      }).toList();

      result.add(tasksInRange.length);
    }
    return result;
  }
}
