import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_data_bundle.dart';
import '../models/task_enums.dart';
import '../repositories/local_task_repository.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../usecases/task_data_usecase.dart';

class TaskProvider extends ChangeNotifier {
  final TaskDataUseCase _taskDataUseCase;
  final NotificationService _notificationService;
  final Uuid _uuid;

  TaskProvider({
    TaskDataUseCase? taskDataUseCase,
    TaskRepository? taskRepository,
    NotificationService? notificationService,
    Uuid? uuid,
  })  : _taskDataUseCase = taskDataUseCase ??
            TaskDataUseCase(taskRepository ?? LocalTaskRepository()),
        _notificationService = notificationService ?? NotificationService(),
        _uuid = uuid ?? const Uuid();

  List<Task> _tasks = [];
  List<Task> _deletedTasks = []; // 回收站
  TaskFilter _filter = TaskFilter.all;
  TaskCategory? _categoryFilter;
  String _searchQuery = '';
  TaskSortType _sortType = TaskSortType.createdTime;
  bool _sortAscending = false;
  StatsTimeFilter _statsTimeFilter = StatsTimeFilter.all;  // 统计时间范围
  DateTime? _customStatsStartDate;  // 自定义统计开始日期
  DateTime? _customStatsEndDate;    // 自定义统计结束日期

  List<Task> get tasks => _getFilteredTasks();
  List<Task> get allTasks => List.unmodifiable(_tasks);
  TaskFilter get filter => _filter;
  TaskCategory? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;
  TaskSortType get sortType => _sortType;
  bool get sortAscending => _sortAscending;
  List<Task> get deletedTasks => _deletedTasks;

  Task? getTaskById(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    return _tasks[index];
  }

  // Statistics getters
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;
  int get activeTasks => _tasks.where((t) => !t.isCompleted).length;
  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  Map<TaskCategory, int> get tasksByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = _tasks.where((t) => t.category == category).length;
    }
    return result;
  }

  Map<TaskCategory, int> get completedByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = _tasks
          .where((t) => t.category == category && t.isCompleted)
          .length;
    }
    return result;
  }

  List<int> get weeklyCompletionTrend {
    final List<int> result = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = _tasks
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

      final count = _tasks
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
    final monthEnd = DateTime(year, month + 1, 0); // 该月最后一天

    for (int day = 1; day <= monthEnd.day; day++) {
      final date = DateTime(year, month, day);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // 统计该日完成的任务数
      final completedCount = _tasks
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

    return _tasks
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(dayStart) &&
            t.completedAt!.isBefore(dayEnd))
        .toList();
  }

  // Stats time filter getter and setter
  StatsTimeFilter get statsTimeFilter => _statsTimeFilter;

  void setStatsTimeFilter(StatsTimeFilter filter) {
    _statsTimeFilter = filter;
    notifyListeners();
  }

  /// 设置自定义统计时间范围
  void setCustomStatsDateRange(DateTime? startDate, DateTime? endDate) {
    _customStatsStartDate = startDate;
    _customStatsEndDate = endDate;
    _statsTimeFilter = StatsTimeFilter.custom;
    notifyListeners();
  }

  /// 获取自定义时间范围
  (DateTime?, DateTime?) get customStatsDateRange =>
      (_customStatsStartDate, _customStatsEndDate);

  /// 根据时间过滤获取任务列表
  List<Task> get _filteredTasksByTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_statsTimeFilter) {
      case StatsTimeFilter.all:
        return _tasks;
      case StatsTimeFilter.year:
        final yearStart = DateTime(now.year, 1, 1);
        return _tasks.where((t) => t.createdAt.isAfter(yearStart)).toList();
      case StatsTimeFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return _tasks.where((t) => t.createdAt.isAfter(monthStart)).toList();
      case StatsTimeFilter.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return _tasks.where((t) => t.createdAt.isAfter(weekStart)).toList();
      case StatsTimeFilter.today:
        final dayStart = today;
        final dayEnd = today.add(const Duration(days: 1));
        return _tasks.where((t) =>
            t.createdAt.isAfter(dayStart) && t.createdAt.isBefore(dayEnd)).toList();
      case StatsTimeFilter.custom:
        if (_customStatsStartDate == null || _customStatsEndDate == null) {
          return _tasks;
        }
        final startDate = DateTime(
          _customStatsStartDate!.year,
          _customStatsStartDate!.month,
          _customStatsStartDate!.day,
        );
        final endDate = DateTime(
          _customStatsEndDate!.year,
          _customStatsEndDate!.month,
          _customStatsEndDate!.day,
        ).add(const Duration(days: 1));
        return _tasks.where((t) =>
            t.createdAt.isAfter(startDate) && t.createdAt.isBefore(endDate)).toList();
    }
  }

  // Filtered statistics getters
  int get filteredTotalTasks => _filteredTasksByTime.length;
  int get filteredCompletedTasks =>
      _filteredTasksByTime.where((t) => t.isCompleted).length;
  int get filteredActiveTasks =>
      _filteredTasksByTime.where((t) => !t.isCompleted).length;
  double get filteredCompletionRate =>
      filteredTotalTasks > 0 ? filteredCompletedTasks / filteredTotalTasks : 0.0;

  Map<TaskCategory, int> get filteredTasksByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] =
          _filteredTasksByTime.where((t) => t.category == category).length;
    }
    return result;
  }

  Map<TaskCategory, int> get filteredCompletedByCategory {
    final Map<TaskCategory, int> result = {};
    for (final category in TaskCategory.values) {
      result[category] = _filteredTasksByTime
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

      // 根据时间过滤应用额外过滤
      final tasksInRange = _filteredTasksByTime.where((t) {
        // 如果是 today/week/month/year 过滤器，只统计该范围内的已完成任务
        if (_statsTimeFilter != StatsTimeFilter.all) {
          return t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(dayStart) &&
              t.completedAt!.isBefore(dayEnd);
        }
        // all 模式下统计所有已完成任务
        return t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(dayStart) &&
            t.completedAt!.isBefore(dayEnd);
      }).toList();

      result.add(tasksInRange.length);
    }
    return result;
  }

  Future<void> initialize() async {
    final bundle = await _taskDataUseCase.initialize();
    _tasks = bundle.tasks;
    _deletedTasks = bundle.deletedTasks;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    final bundle = await _taskDataUseCase.initialize();
    _tasks = bundle.tasks;
    notifyListeners();
  }

  Future<Task> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    Priority priority = Priority.medium,
    TaskCategory category = TaskCategory.other,
    RepeatType repeatType = RepeatType.none,
    String? parentId,
    List<String> customTagIds = const [],
    DateTime? reminderTime,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      reminderTime: reminderTime,
      category: category,
      createdAt: DateTime.now(),
      repeatType: repeatType,
      parentId: parentId,
      customTagIds: customTagIds,
    );

    _tasks.add(task);
    await _taskDataUseCase.persistTasks(_tasks);
    if (!task.isCompleted && task.reminderTime != null && task.dueDate != null) {
      await _notificationService.scheduleTaskReminder(task);
    }
    notifyListeners();
    return task;
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final previousTask = _tasks[index];
      _tasks[index] = task;
      await _taskDataUseCase.persistTasks(_tasks);

      // 任务更新后先取消旧提醒，再根据新配置重建提醒。
      await _notificationService.cancelReminder(previousTask.id);
      if (!task.isCompleted && task.reminderTime != null && task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }

      notifyListeners();
    }
  }

  Future<void> deleteTask(String id, {bool permanent = false}) async {
    if (permanent) {
      // 永久删除
      _deletedTasks.removeWhere((t) => t.id == id);
    } else {
      // 移到回收站
      final taskIndex = _tasks.indexWhere((t) => t.id == id);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        _deletedTasks.add(task);
        _tasks.removeAt(taskIndex);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    await _taskDataUseCase.persistDeletedTasks(_deletedTasks);
    await _notificationService.cancelReminder(id);
    notifyListeners();
  }

  /// 从回收站恢复任务
  Future<void> restoreTask(String id) async {
    final taskIndex = _deletedTasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = _deletedTasks[taskIndex];
      _tasks.add(task);
      _deletedTasks.removeAt(taskIndex);
      if (!task.isCompleted && task.reminderTime != null && task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    await _taskDataUseCase.persistDeletedTasks(_deletedTasks);
    notifyListeners();
  }

  /// 清空回收站
  Future<void> clearDeletedTasks() async {
    _deletedTasks.clear();
    await _taskDataUseCase.clearDeletedTasks();
    notifyListeners();
  }

  /// 加载回收站数据
  Future<void> loadDeletedTasks() async {
    final bundle = await _taskDataUseCase.initialize();
    _deletedTasks = bundle.deletedTasks;
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final willComplete = !task.isCompleted;

      final updatedTask = task.copyWith(
        isCompleted: willComplete,
        completedAt: willComplete ? DateTime.now() : null,
      );
      _tasks[index] = updatedTask;

      // 如果是标记为完成且有重复类型，生成下一个重复任务
      if (willComplete && task.repeatType != RepeatType.none) {
        _createNextRepeatTask(task);
      }

      await _taskDataUseCase.persistTasks(_tasks);

      if (willComplete) {
        await _notificationService.cancelReminder(task.id);
      } else if (updatedTask.reminderTime != null && updatedTask.dueDate != null) {
        await _notificationService.scheduleTaskReminder(updatedTask);
      }

      notifyListeners();
    }
  }

  Future<void> replaceAllTasks(
    List<Task> tasks, {
    bool clearDeletedTasks = false,
    List<Task>? deletedTasks,
  }) async {
    _tasks = List<Task>.from(tasks);
    await _taskDataUseCase.persistTasks(_tasks);

    if (deletedTasks != null) {
      _deletedTasks = List<Task>.from(deletedTasks);
      await _taskDataUseCase.persistDeletedTasks(_deletedTasks);
    } else if (clearDeletedTasks) {
      _deletedTasks.clear();
      await _taskDataUseCase.clearDeletedTasks();
    }

    await _notificationService.cancelAllReminders();
    for (final task in _tasks) {
      if (!task.isCompleted && task.reminderTime != null && task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    }

    notifyListeners();
  }

  Future<void> mergeTasks(List<Task> importedTasks) async {
    final mergedById = <String, Task>{
      for (final task in _tasks) task.id: task,
    };
    for (final task in importedTasks) {
      mergedById[task.id] = task;
    }
    _tasks = mergedById.values.toList();
    await _taskDataUseCase.persistTasks(_tasks);

    await _notificationService.cancelAllReminders();
    for (final task in _tasks) {
      if (!task.isCompleted && task.reminderTime != null && task.dueDate != null) {
        await _notificationService.scheduleTaskReminder(task);
      }
    }

    notifyListeners();
  }

  Future<String?> exportTaskBackup() {
    return _taskDataUseCase.exportTaskBundle(
      tasks: _tasks,
      deletedTasks: _deletedTasks,
    );
  }

  Future<TaskDataBundle?> importTaskBackup(String filePath) {
    return _taskDataUseCase.importTaskBundle(filePath);
  }

  /// 创建下一个重复任务
  void _createNextRepeatTask(Task originalTask) {
    DateTime? nextDueDate;

    if (originalTask.dueDate != null) {
      switch (originalTask.repeatType) {
        case RepeatType.daily:
          nextDueDate = originalTask.dueDate!.add(const Duration(days: 1));
          break;
        case RepeatType.weekly:
          nextDueDate = originalTask.dueDate!.add(const Duration(days: 7));
          break;
        case RepeatType.monthly:
          nextDueDate = _addMonthsKeepingDay(originalTask.dueDate!, 1);
          break;
        case RepeatType.yearly:
          nextDueDate = _addYearsKeepingDay(originalTask.dueDate!, 1);
          break;
        case RepeatType.none:
          break;
      }
    }

    final nextTask = Task(
      id: _uuid.v4(),
      title: originalTask.title,
      description: originalTask.description,
      dueDate: nextDueDate,
      priority: originalTask.priority,
      category: originalTask.category,
      createdAt: DateTime.now(),
      repeatType: originalTask.repeatType,
      parentId: originalTask.id,
      customTagIds: originalTask.customTagIds,
      reminderTime: _nextReminderTime(originalTask, nextDueDate),
    );

    _tasks.add(nextTask);
  }

  DateTime? _nextReminderTime(Task originalTask, DateTime? nextDueDate) {
    if (originalTask.reminderTime == null ||
        originalTask.dueDate == null ||
        nextDueDate == null) {
      return null;
    }
    final offset = originalTask.dueDate!.difference(originalTask.reminderTime!);
    return nextDueDate.subtract(offset);
  }

  DateTime _addMonthsKeepingDay(DateTime source, int months) {
    final baseMonth = source.month - 1 + months;
    final targetYear = source.year + (baseMonth ~/ 12);
    final targetMonth = (baseMonth % 12) + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = source.day > lastDay ? lastDay : source.day;
    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  DateTime _addYearsKeepingDay(DateTime source, int years) {
    final targetYear = source.year + years;
    final lastDay = DateTime(targetYear, source.month + 1, 0).day;
    final targetDay = source.day > lastDay ? lastDay : source.day;
    return DateTime(
      targetYear,
      source.month,
      targetDay,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortType(TaskSortType sortType) {
    if (_sortType == sortType) {
      _sortAscending = !_sortAscending;
    } else {
      _sortType = sortType;
      _sortAscending = false;
    }
    notifyListeners();
  }

  List<Task> _getFilteredTasks() {
    List<Task> result = List.from(_tasks);

    // Apply status filter
    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Apply category filter
    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        return t.title.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort tasks
    result.sort((a, b) {
      // 未完成的任务排在前面
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      int compareResult;
      switch (_sortType) {
        case TaskSortType.createdTime:
          compareResult = b.createdAt.compareTo(a.createdAt);
          break;
        case TaskSortType.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            compareResult = 0;
          } else if (a.dueDate == null) {
            compareResult = 1;
          } else if (b.dueDate == null) {
            compareResult = -1;
          } else {
            compareResult = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case TaskSortType.priority:
          compareResult = b.priority.index.compareTo(a.priority.index);
          break;
      }

      return _sortAscending ? -compareResult : compareResult;
    });

    return result;
  }
}
