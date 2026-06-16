import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/ai_mode_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_dispatcher_service.dart';
import '../widgets/task_card.dart';
import '../widgets/ui/ui.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

enum _QuickFilter { all, today, tomorrow, week, completed }

class _TaskGroup {
  final String title;
  final String? subtitle;
  final List<Task> tasks;
  final Color? accentColor;

  const _TaskGroup({
    required this.title,
    required this.tasks,
    this.subtitle,
    this.accentColor,
  });
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocusNode = FocusNode();
  final Set<String> _selectedTasks = {};

  bool _isMultiSelectMode = false;
  bool _isCreatingFromCommand = false;
  _QuickFilter _quickFilter = _QuickFilter.all;

  @override
  void dispose() {
    _commandController.dispose();
    _commandFocusNode.dispose();
    super.dispose();
  }

  void _setQuickFilter(_QuickFilter filter) {
    final provider = context.read<TaskProvider>();
    final today = _dayOnly(DateTime.now());

    setState(() {
      _quickFilter = filter;
    });

    provider.setCategoryFilter(null);
    provider.setTagFilter(null);
    provider.clearDateRangeFilter();

    switch (filter) {
      case _QuickFilter.all:
        provider.setFilter(TaskFilter.all);
        break;
      case _QuickFilter.today:
        provider.setFilter(TaskFilter.all);
        provider.setDateRangeFilter(today, today);
        break;
      case _QuickFilter.tomorrow:
        final tomorrow = today.add(const Duration(days: 1));
        provider.setFilter(TaskFilter.all);
        provider.setDateRangeFilter(tomorrow, tomorrow);
        break;
      case _QuickFilter.week:
        final endOfWeek = today.add(Duration(days: 7 - today.weekday));
        provider.setFilter(TaskFilter.all);
        provider.setDateRangeFilter(today, endOfWeek);
        break;
      case _QuickFilter.completed:
        provider.setFilter(TaskFilter.completed);
        break;
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedTasks.clear();
      }
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTasks.contains(taskId)) {
        _selectedTasks.remove(taskId);
      } else {
        _selectedTasks.add(taskId);
      }
    });
  }

  void _selectAll(List<Task> tasks) {
    setState(() {
      if (_selectedTasks.length == tasks.length) {
        _selectedTasks.clear();
      } else {
        _selectedTasks
          ..clear()
          ..addAll(tasks.map((task) => task.id));
      }
    });
  }

  Future<void> _batchComplete() async {
    final provider = context.read<TaskProvider>();
    final selectedIds = List<String>.from(_selectedTasks);

    for (final taskId in selectedIds) {
      await provider.toggleTaskCompletion(taskId);
    }

    if (!mounted) return;
    setState(() {
      _selectedTasks.clear();
      _isMultiSelectMode = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('批量操作完成')));
  }

  void _batchDelete() {
    if (_selectedTasks.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除选中的 ${_selectedTasks.length} 个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final provider = context.read<TaskProvider>();
              final selectedIds = List<String>.from(_selectedTasks);

              for (final taskId in selectedIds) {
                await provider.deleteTask(taskId);
              }

              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {
                _selectedTasks.clear();
                _isMultiSelectMode = false;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('批量删除完成')));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTaskFromCommand() async {
    final text = _commandController.text.trim();
    if (text.isEmpty || _isCreatingFromCommand) {
      _commandFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isCreatingFromCommand = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final taskProvider = context.read<TaskProvider>();
    final preferRemote = context.read<AiModeProvider>().preferRemote;

    try {
      final parsed = await AiDispatcherService().parseTask(
        text,
        preferRemote: preferRemote,
      );

      if (!mounted) return;

      if (parsed.title.trim().isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('没有识别到任务标题')));
        return;
      }

      final task = await taskProvider.addTask(
        title: parsed.title,
        description: parsed.description,
        dueDate: parsed.dueDate,
        priority: parsed.priority ?? Priority.medium,
        category: parsed.suggestedCategory ?? TaskCategory.other,
      );

      if (!mounted) return;
      _commandController.clear();
      taskProvider.setSearchQuery('');
      messenger.showSnackBar(SnackBar(content: Text('已创建任务：${task.title}')));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingFromCommand = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildQuickFilters(context),
                    _isMultiSelectMode
                        ? _buildSelectionToolbar(context)
                        : _buildListToolbar(context),
                    Expanded(child: _buildTaskList(context)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _isMultiSelectMode
          ? _buildBatchFloatingActions(context)
          : FloatingActionButton(
              tooltip: '添加任务',
              onPressed: () => _navigateToAdd(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AiTODO',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${provider.activeTasks} 个待办 · ${provider.completedTasks} 个已完成',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '聚焦输入',
                icon: const Icon(Icons.search),
                onPressed: () => _commandFocusNode.requestFocus(),
              ),
              IconButton(
                tooltip: '设置',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCommandField(
            controller: _commandController,
            hintText: '输入任务或问 AI...',
            onChanged: (value) {
              context.read<TaskProvider>().setSearchQuery(value);
            },
            onSubmitted: (_) {
              _createTaskFromCommand();
            },
            onClear: () {
              _commandController.clear();
              context.read<TaskProvider>().setSearchQuery('');
            },
            onActionPressed: _createTaskFromCommand,
            actionIcon: _isCreatingFromCommand
                ? Icons.hourglass_empty
                : Icons.auto_awesome,
            actionTooltip: '智能创建任务',
            actionEnabled: !_isCreatingFromCommand,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - today.weekday));
    final allTasks = provider.allTasks;

    return SizedBox(
      height: 46,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        children: [
          AppFilterChip(
            label: '全部',
            selected: _quickFilter == _QuickFilter.all,
            count: allTasks.length,
            onTap: () => _setQuickFilter(_QuickFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppFilterChip(
            label: '今天',
            selected: _quickFilter == _QuickFilter.today,
            count: _countDueInRange(allTasks, today, today),
            onTap: () => _setQuickFilter(_QuickFilter.today),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppFilterChip(
            label: '明天',
            selected: _quickFilter == _QuickFilter.tomorrow,
            count: _countDueInRange(allTasks, tomorrow, tomorrow),
            onTap: () => _setQuickFilter(_QuickFilter.tomorrow),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppFilterChip(
            label: '本周',
            selected: _quickFilter == _QuickFilter.week,
            count: _countDueInRange(allTasks, today, weekEnd),
            onTap: () => _setQuickFilter(_QuickFilter.week),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppFilterChip(
            label: '已完成',
            selected: _quickFilter == _QuickFilter.completed,
            count: provider.completedTasks,
            onTap: () => _setQuickFilter(_QuickFilter.completed),
          ),
        ],
      ),
    );
  }

  Widget _buildListToolbar(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _showSortMenu(context),
              icon: Icon(
                provider.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
              label: Text(_sortLabel(provider)),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _toggleMultiSelectMode,
            icon: const Icon(Icons.radio_button_unchecked),
            label: const Text('批量'),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.tune),
            label: const Text('筛选'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;
    final colorScheme = Theme.of(context).colorScheme;

    return AppSurface(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: colorScheme.primaryContainer.withValues(alpha: 0.45),
      borderColor: colorScheme.primary.withValues(alpha: 0.24),
      child: Row(
        children: [
          IconButton(
            tooltip: '退出批量选择',
            icon: const Icon(Icons.close),
            onPressed: _toggleMultiSelectMode,
          ),
          Expanded(
            child: Text(
              '已选择 ${_selectedTasks.length} 项',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: tasks.isEmpty ? null : () => _selectAll(tasks),
            child: Text(_selectedTasks.length == tasks.length ? '取消全选' : '全选'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final tasks = provider.tasks;

        if (tasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: provider.loadTasks,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.45,
                  child: AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: _emptyTitle(provider),
                    message: '可以直接输入一句话，然后点右侧 AI 按钮创建任务。',
                    action: FilledButton.icon(
                      onPressed: () => _commandFocusNode.requestFocus(),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('输入新任务'),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final groups = _buildGroups(context, tasks);

        return RefreshIndicator(
          onRefresh: provider.loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _buildTaskGroup(context, provider, group);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskGroup(
    BuildContext context,
    TaskProvider provider,
    _TaskGroup group,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: group.title,
          subtitle: group.subtitle,
          count: group.tasks.length,
          accentColor: group.accentColor,
        ),
        AppSurface(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < group.tasks.length; index++) ...[
                TaskCard(
                  task: group.tasks[index],
                  onTap: () {
                    if (_isMultiSelectMode) {
                      _toggleTaskSelection(group.tasks[index].id);
                    } else {
                      _navigateToEdit(context, group.tasks[index]);
                    }
                  },
                  onToggle: () =>
                      provider.toggleTaskCompletion(group.tasks[index].id),
                  onDeleteConfirm: () =>
                      _showDeleteDialog(context, group.tasks[index]),
                  isMultiSelectMode: _isMultiSelectMode,
                  isSelected: _selectedTasks.contains(group.tasks[index].id),
                  onSelect: () => _toggleTaskSelection(group.tasks[index].id),
                ),
                if (index < group.tasks.length - 1)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatchFloatingActions(BuildContext context) {
    final hasSelection = _selectedTasks.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'delete',
          tooltip: '批量删除',
          onPressed: hasSelection ? _batchDelete : null,
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          child: const Icon(Icons.delete_outline),
        ),
        const SizedBox(width: AppSpacing.md),
        FloatingActionButton(
          heroTag: 'complete',
          tooltip: '批量完成',
          onPressed: hasSelection ? _batchComplete : null,
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  void _showSortMenu(BuildContext context) {
    final provider = context.read<TaskProvider>();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '排序方式',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSortOption(
                  context,
                  '创建时间',
                  TaskSortType.createdTime,
                  Icons.access_time,
                  provider,
                ),
                _buildSortOption(
                  context,
                  '截止日期',
                  TaskSortType.dueDate,
                  Icons.event_outlined,
                  provider,
                ),
                _buildSortOption(
                  context,
                  '优先级',
                  TaskSortType.priority,
                  Icons.flag_outlined,
                  provider,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    TaskSortType sortType,
    IconData icon,
    TaskProvider provider,
  ) {
    final isSelected = provider.sortType == sortType;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              provider.sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
            )
          : null,
      selected: isSelected,
      onTap: () {
        provider.setSortType(sortType);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Consumer2<TaskProvider, TagProvider>(
            builder: (context, taskProvider, tagProvider, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '筛选任务',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            taskProvider.setCategoryFilter(null);
                            taskProvider.setTagFilter(null);
                          },
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '分类',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: TaskCategory.values.map((category) {
                        final selected =
                            taskProvider.categoryFilter == category;
                        return AppFilterChip(
                          label: category.label,
                          icon: category.icon,
                          color: category.color,
                          selected: selected,
                          onTap: () {
                            taskProvider.setCategoryFilter(
                              selected ? null : category,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '标签',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (tagProvider.tags.isEmpty)
                          Text(
                            '暂无自定义标签',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ...tagProvider.tags.map((tag) {
                          final selected = taskProvider.tagFilter == tag.id;
                          return AppFilterChip(
                            label: tag.name,
                            color: tag.color,
                            selected: selected,
                            onTap: () {
                              taskProvider.setTagFilter(
                                selected ? null : tag.id,
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<_TaskGroup> _buildGroups(BuildContext context, List<Task> tasks) {
    final today = _dayOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(Duration(days: 7 - today.weekday));
    final colorScheme = Theme.of(context).colorScheme;

    final todayTasks = <Task>[];
    final tomorrowTasks = <Task>[];
    final weekTasks = <Task>[];
    final laterTasks = <Task>[];
    final unscheduledTasks = <Task>[];
    final completedTasks = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted) {
        completedTasks.add(task);
        continue;
      }

      final dueDate = task.dueDate == null ? null : _dayOnly(task.dueDate!);
      if (dueDate == null) {
        unscheduledTasks.add(task);
      } else if (_isSameDay(dueDate, today)) {
        todayTasks.add(task);
      } else if (_isSameDay(dueDate, tomorrow)) {
        tomorrowTasks.add(task);
      } else if (!dueDate.isBefore(today) && !dueDate.isAfter(weekEnd)) {
        weekTasks.add(task);
      } else {
        laterTasks.add(task);
      }
    }

    final groups = <_TaskGroup>[
      if (todayTasks.isNotEmpty)
        _TaskGroup(
          title: '今天',
          subtitle: _formatSectionDate(today),
          tasks: todayTasks,
          accentColor: colorScheme.primary,
        ),
      if (tomorrowTasks.isNotEmpty)
        _TaskGroup(
          title: '明天',
          subtitle: _formatSectionDate(tomorrow),
          tasks: tomorrowTasks,
          accentColor: Colors.teal,
        ),
      if (weekTasks.isNotEmpty)
        _TaskGroup(title: '本周稍后', tasks: weekTasks, accentColor: Colors.blue),
      if (laterTasks.isNotEmpty)
        _TaskGroup(title: '稍后', tasks: laterTasks, accentColor: Colors.indigo),
      if (unscheduledTasks.isNotEmpty)
        _TaskGroup(
          title: '未安排',
          tasks: unscheduledTasks,
          accentColor: Colors.orange,
        ),
      if (completedTasks.isNotEmpty)
        _TaskGroup(
          title: '已完成',
          tasks: completedTasks,
          accentColor: Colors.green,
        ),
    ];

    if (groups.isEmpty && tasks.isNotEmpty) {
      return [
        _TaskGroup(title: '任务', tasks: tasks, accentColor: colorScheme.primary),
      ];
    }

    return groups;
  }

  String _sortLabel(TaskProvider provider) {
    final direction = provider.sortAscending ? '升序' : '降序';
    switch (provider.sortType) {
      case TaskSortType.createdTime:
        return '按创建时间 · $direction';
      case TaskSortType.dueDate:
        return '按截止时间 · $direction';
      case TaskSortType.priority:
        return '按优先级 · $direction';
    }
  }

  String _formatSectionDate(DateTime date) {
    return '${DateFormat('M月d日').format(date)} · ${_weekdayLabel(date)}';
  }

  String _weekdayLabel(DateTime date) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[date.weekday - 1];
  }

  String _emptyTitle(TaskProvider provider) {
    if (provider.searchQuery.isNotEmpty ||
        provider.filter != TaskFilter.all ||
        provider.categoryFilter != null ||
        provider.tagFilter != null ||
        provider.dateFrom != null ||
        provider.dateTo != null) {
      return '没有匹配的任务';
    }
    return '暂无任务';
  }

  int _countDueInRange(List<Task> tasks, DateTime from, DateTime to) {
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final dueDate = _dayOnly(task.dueDate!);
      return !dueDate.isBefore(from) && !dueDate.isAfter(to);
    }).length;
  }

  DateTime _dayOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
  }

  void _navigateToEdit(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, Task task) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final taskProvider = context.read<TaskProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务“${task.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      await taskProvider.deleteTask(task.id);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('任务已删除')));
      return true;
    }
    return false;
  }
}
