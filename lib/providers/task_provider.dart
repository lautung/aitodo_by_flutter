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
  String? _groupFilter; // 分组筛选
  String? _tagFilter; // 标签筛选
  List<String> _tagFilters = []; // 多标签筛选
  TagFilterMode _tagFilterMode = TagFilterMode.or; // 标签筛选模式
  DateTime? _dateFrom; // 开始日期筛选
  DateTime? _dateTo; // 结束日期筛选
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
  String? get groupFilter => _groupFilter;
  String? get tagFilter => _tagFilter;
  List<String> get tagFilters => _tagFilters;
  TagFilterMode get tagFilterMode => _tagFilterMode;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
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
    List<String> prerequisiteIds = const [],
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
      prerequisiteIds: prerequisiteIds,
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

  Future<bool> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final willComplete = !task.isCompleted;

      // 如果是要完成，检查前置任务是否都已完成
      if (willComplete && !canCompleteTask(id)) {
        return false;
      }

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
      return true;
    }
    return false;
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

  /// 导出为 CSV 格式
  Future<String?> exportToCsv({
    List<Task>? tasks,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final exportTasks = tasks ?? _tasks;

    // Apply date range filter if specified
    var filteredTasks = exportTasks;
    if (dateFrom != null || dateTo != null) {
      filteredTasks = exportTasks.where((t) {
        if (t.dueDate == null) return false;
        if (dateFrom != null && t.dueDate!.isBefore(dateFrom)) return false;
        if (dateTo != null && t.dueDate!.isAfter(dateTo)) return false;
        return true;
      }).toList();
    }

    final buffer = StringBuffer();

    // CSV header
    buffer.writeln('标题,描述,优先级,分类,截止日期,状态,创建时间,标签');

    // CSV data
    final dateFormat = 'yyyy-MM-dd HH:mm';
    for (final task in filteredTasks) {
      final title = _escapeCsv(task.title);
      final description = _escapeCsv(task.description ?? '');
      final priority = task.priority.label;
      final category = task.category.label;
      final dueDate = task.dueDate != null
          ? _formatDate(task.dueDate!, dateFormat)
          : '';
      final status = task.isCompleted ? '已完成' : '进行中';
      final createdAt = _formatDate(task.createdAt, dateFormat);
      final tags = task.customTagIds.join(';');

      buffer.writeln('$title,$description,$priority,$category,$dueDate,$status,$createdAt,$tags');
    }

    return buffer.toString();
  }

  /// 导出为 Markdown 格式
  Future<String?> exportToMarkdown({
    List<Task>? tasks,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final exportTasks = tasks ?? _tasks;

    // Apply date range filter if specified
    var filteredTasks = exportTasks;
    if (dateFrom != null || dateTo != null) {
      filteredTasks = exportTasks.where((t) {
        if (t.dueDate == null) return false;
        if (dateFrom != null && t.dueDate!.isBefore(dateFrom)) return false;
        if (dateTo != null && t.dueDate!.isAfter(dateTo)) return false;
        return true;
      }).toList();
    }

    final buffer = StringBuffer();
    final dateFormat = 'yyyy-MM-dd HH:mm';

    buffer.writeln('# 任务导出');
    buffer.writeln();
    buffer.writeln('> 导出时间: ${_formatDate(DateTime.now(), dateFormat)}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();

    // 按状态分组
    final activeTasks = filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();

    if (activeTasks.isNotEmpty) {
      buffer.writeln('## 进行中的任务 (${activeTasks.length})');
      buffer.writeln();
      for (final task in activeTasks) {
        _writeTaskAsMarkdown(buffer, task, dateFormat);
      }
    }

    if (completedTasks.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## 已完成的任务 (${completedTasks.length})');
      buffer.writeln();
      for (final task in completedTasks) {
        _writeTaskAsMarkdown(buffer, task, dateFormat);
      }
    }

    return buffer.toString();
  }

  void _writeTaskAsMarkdown(StringBuffer buffer, Task task, String dateFormat) {
    buffer.writeln('### ${task.title}');
    if (task.description != null && task.description!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${task.description}');
    }
    buffer.writeln();
    buffer.writeln('- 优先级: ${task.priority.label}');
    buffer.writeln('- 分类: ${task.category.label}');
    if (task.dueDate != null) {
      buffer.writeln('- 截止日期: ${_formatDate(task.dueDate!, dateFormat)}');
    }
    if (task.customTagIds.isNotEmpty) {
      buffer.writeln('- 标签: ${task.customTagIds.join(", ")}');
    }
    if (task.isCompleted && task.completedAt != null) {
      buffer.writeln('- 完成时间: ${_formatDate(task.completedAt!, dateFormat)}');
    }
    buffer.writeln('- 创建时间: ${_formatDate(task.createdAt, dateFormat)}');
    buffer.writeln();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _formatDate(DateTime date, String format) {
    // Simple date formatting
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        case RepeatType.custom:
          if (originalTask.customRepeat != null) {
            nextDueDate = originalTask.customRepeat!.getNextDate(originalTask.dueDate!);
          }
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
      customRepeat: originalTask.customRepeat,
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

  void setGroupFilter(String? groupId) {
    _groupFilter = groupId;
    notifyListeners();
  }

  /// 设置标签筛选
  void setTagFilter(String? tagId) {
    _tagFilter = tagId;
    notifyListeners();
  }

  /// 设置多标签筛选
  void setTagFilters(List<String> tagIds) {
    _tagFilters = tagIds;
    notifyListeners();
  }

  /// 添加标签到筛选
  void addTagToFilter(String tagId) {
    if (!_tagFilters.contains(tagId)) {
      _tagFilters.add(tagId);
      notifyListeners();
    }
  }

  /// 从筛选中移除标签
  void removeTagFromFilter(String tagId) {
    _tagFilters.remove(tagId);
    notifyListeners();
  }

  /// 清除所有标签筛选
  void clearTagFilters() {
    _tagFilters.clear();
    _tagFilter = null;
    notifyListeners();
  }

  /// 设置标签筛选模式
  void setTagFilterMode(TagFilterMode mode) {
    _tagFilterMode = mode;
    notifyListeners();
  }

  /// 设置日期范围筛选
  void setDateRangeFilter(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    notifyListeners();
  }

  /// 清除日期范围筛选
  void clearDateRangeFilter() {
    _dateFrom = null;
    _dateTo = null;
    notifyListeners();
  }

  // ============= 批量操作 =============

  /// 批量完成/取消完成任务
  Future<void> batchToggleCompletion(List<String> taskIds, {bool? markAsComplete}) async {
    for (final id in taskIds) {
      final task = getTaskById(id);
      if (task == null) continue;

      final shouldComplete = markAsComplete ?? !task.isCompleted;
      if (shouldComplete && !task.isCompleted) {
        // 检查依赖
        if (!canCompleteTask(id)) {
          continue;
        }
      }

      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final updatedTask = _tasks[index].copyWith(
          isCompleted: shouldComplete,
          completedAt: shouldComplete ? DateTime.now() : null,
        );
        _tasks[index] = updatedTask;

        if (shouldComplete) {
          await _notificationService.cancelReminder(id);
        }
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 批量删除任务（移到回收站）
  Future<void> batchDelete(List<String> taskIds) async {
    for (final id in taskIds) {
      await deleteTask(id);
    }
  }

  /// 批量永久删除任务
  Future<void> batchPermanentDelete(List<String> taskIds) async {
    for (final id in taskIds) {
      await deleteTask(id, permanent: true);
    }
  }

  /// 批量恢复任务
  Future<void> batchRestore(List<String> taskIds) async {
    for (final id in taskIds) {
      await restoreTask(id);
    }
  }

  /// 批量移动到分组
  Future<void> batchMoveToGroup(List<String> taskIds, String? groupId) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(groupId: groupId);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 批量添加标签
  Future<void> batchAddTags(List<String> taskIds, List<String> tagIds) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTagIds = List<String>.from(_tasks[index].customTagIds);
        for (final tagId in tagIds) {
          if (!currentTagIds.contains(tagId)) {
            currentTagIds.add(tagId);
          }
        }
        _tasks[index] = _tasks[index].copyWith(customTagIds: currentTagIds);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 批量移除标签
  Future<void> batchRemoveTags(List<String> taskIds, List<String> tagIds) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTagIds = List<String>.from(_tasks[index].customTagIds);
        currentTagIds.removeWhere((tagId) => tagIds.contains(tagId));
        _tasks[index] = _tasks[index].copyWith(customTagIds: currentTagIds);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 批量更新优先级
  Future<void> batchUpdatePriority(List<String> taskIds, Priority priority) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(priority: priority);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 批量更新截止日期
  Future<void> batchUpdateDueDate(List<String> taskIds, DateTime? dueDate) async {
    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(dueDate: dueDate);
      }
    }
    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  /// 重新排序任务
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);

    // 更新 sortOrder
    for (var i = 0; i < _tasks.length; i++) {
      _tasks[i] = _tasks[i].copyWith(sortOrder: i);
    }

    await _taskDataUseCase.persistTasks(_tasks);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 获取指定标签的任务
  List<Task> getTasksByTag(String tagId) {
    return _tasks.where((t) => t.customTagIds.contains(tagId)).toList();
  }

  /// 获取指定多个标签的任务（任一匹配）
  List<Task> getTasksByTags(List<String> tagIds) {
    if (tagIds.isEmpty) return [];
    return _tasks.where((t) => t.customTagIds.any((tagId) => tagIds.contains(tagId))).toList();
  }

  /// 获取指定多个标签的任务（全部匹配）
  List<Task> getTasksByAllTags(List<String> tagIds) {
    if (tagIds.isEmpty) return _tasks;
    return _tasks.where((t) => tagIds.every((tagId) => t.customTagIds.contains(tagId))).toList();
  }

  // ============= Task Dependencies =============

  /// 检查任务是否可完成（所有前置任务都已完成）
  bool canCompleteTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return false;
    if (task.prerequisiteIds.isEmpty) return true;

    for (final prereqId in task.prerequisiteIds) {
      final prereqTask = getTaskById(prereqId);
      if (prereqTask == null || !prereqTask.isCompleted) {
        return false;
      }
    }
    return true;
  }

  /// 获取任务的前置任务列表
  List<Task> getPrerequisiteTasks(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return [];
    return task.prerequisiteIds
        .map((id) => getTaskById(id))
        .whereType<Task>()
        .toList();
  }

  /// 获取依赖该任务的任务列表
  List<Task> getDependentTasks(String taskId) {
    return _tasks.where((t) => t.prerequisiteIds.contains(taskId)).toList();
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

    // Apply group filter
    if (_groupFilter != null) {
      result = result.where((t) => t.groupId == _groupFilter).toList();
    }

    // Apply tag filter (single tag)
    if (_tagFilter != null) {
      result = result.where((t) => t.customTagIds.contains(_tagFilter)).toList();
    }

    // Apply multiple tag filter
    if (_tagFilters.isNotEmpty) {
      if (_tagFilterMode == TagFilterMode.and) {
        // AND mode: task must have ALL selected tags
        result = result.where((t) =>
            _tagFilters.every((tagId) => t.customTagIds.contains(tagId))).toList();
      } else {
        // OR mode: task must have ANY of the selected tags
        result = result.where((t) =>
            t.customTagIds.any((tagId) => _tagFilters.contains(tagId))).toList();
      }
    }

    // Apply date range filter
    if (_dateFrom != null || _dateTo != null) {
      result = result.where((t) {
        if (t.dueDate == null) return false;
        final dueDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        if (_dateFrom != null) {
          final from = DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day);
          if (dueDate.isBefore(from)) return false;
        }
        if (_dateTo != null) {
          final to = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day);
          if (dueDate.isAfter(to)) return false;
        }
        return true;
      }).toList();
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

  /// 获取搜索高亮文本片段
  /// 返回包含匹配范围的列表，每项是 (start, end) 索引
  List<List<int>> getHighlightRanges(String text) {
    if (_searchQuery.isEmpty) return [];

    final ranges = <List<int>>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = _searchQuery.toLowerCase();
    var startIndex = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) break;
      ranges.add([index, index + _searchQuery.length]);
      startIndex = index + _searchQuery.length;
    }

    return ranges;
  }

  /// 检查任务是否匹配当前搜索查询
  bool taskMatchesSearch(Task task) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return task.title.toLowerCase().contains(query) ||
        (task.description?.toLowerCase().contains(query) ?? false);
  }
}
