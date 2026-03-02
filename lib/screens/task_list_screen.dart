import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isMultiSelectMode = false;
  final Set<String> _selectedTasks = {};
  final Map<String, GlobalKey<TaskCardState>> _taskCardKeys = {};
  String? _expandedTaskId;

  void _collapseAllCards() {
    for (final key in _taskCardKeys.values) {
      key.currentState?.collapse();
    }
    _expandedTaskId = null;
  }

  @override
  void initState() {
    super.initState();
    _showSwipeHint();
  }

  Future<void> _showSwipeHint() async {
    // 已移除滑动删除，不再显示提示
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _selectedTasks.addAll(tasks.map((t) => t.id));
      }
    });
  }

  Future<void> _batchComplete() async {
    final provider = context.read<TaskProvider>();
    for (final taskId in _selectedTasks) {
      await provider.toggleTaskCompletion(taskId);
    }
    if (!mounted) return;
    _selectedTasks.clear();
    _toggleMultiSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('批量操作完成')),
    );
  }

  void _batchDelete() {
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
              for (final taskId in _selectedTasks) {
                await provider.deleteTask(taskId);
              }
              _selectedTasks.clear();
              _toggleMultiSelectMode();
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('批量删除完成')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiSelectMode ? '选择任务' : 'AiTODO'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleMultiSelectMode,
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: '全选',
                  onPressed: () {
                    final tasks = context.read<TaskProvider>().tasks;
                    _selectAll(tasks);
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  tooltip: '批量选择',
                  onPressed: _toggleMultiSelectMode,
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: '排序',
                  onPressed: () => _showSortMenu(context),
                ),
              ],
        bottom: _isMultiSelectMode
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<TaskProvider>().setSearchQuery(value);
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索任务...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TaskProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Status filters
                _buildFilterChip(
                  context,
                  '全部',
                  TaskFilter.all,
                  Icons.list,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  '进行中',
                  TaskFilter.active,
                  Icons.pending_actions,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  '已完成',
                  TaskFilter.completed,
                  Icons.check_circle,
                ),
                const SizedBox(width: 16),
                // Category filters
                ...TaskCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(context, category),
                  );
                }),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                final tasks = provider.tasks;

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无任务',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击下方 + 按钮添加新任务',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      _taskCardKeys[task.id] ??= GlobalKey();
                      return TaskCard(
                        task: task,
                        swipeKey: _taskCardKeys[task.id],
                        onTap: () {
                          if (_expandedTaskId != null && _expandedTaskId != task.id) {
                            _collapseAllCards();
                            return;
                          }
                          if (_isMultiSelectMode) {
                            _toggleTaskSelection(task.id);
                          } else {
                            _navigateToEdit(context, task);
                          }
                        },
                        onToggle: () => provider.toggleTaskCompletion(task.id),
                        onDelete: () => provider.deleteTask(task.id),
                        onDeleteConfirm: () => _showDeleteDialog(context, task),
                        isMultiSelectMode: _isMultiSelectMode,
                        isSelected: _selectedTasks.contains(task.id),
                        onSelect: () => _toggleTaskSelection(task.id),
                        onCollapse: () {
                          _expandedTaskId = null;
                        },
                        onExpand: () {
                          _expandedTaskId = task.id;
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'delete',
                  onPressed: _selectedTasks.isNotEmpty ? _batchDelete : null,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  heroTag: 'complete',
                  onPressed: _selectedTasks.isNotEmpty ? _batchComplete : null,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () => _navigateToAdd(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    TaskFilter filter,
    IconData icon,
  ) {
    final provider = context.watch<TaskProvider>();
    final isSelected = provider.filter == filter && provider.categoryFilter == null;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        provider.setFilter(filter);
        provider.setCategoryFilter(null);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    );
  }

  void _showSortMenu(BuildContext context) {
    final provider = context.read<TaskProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '排序方式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                  Icons.calendar_today,
                  provider,
                ),
                _buildSortOption(
                  context,
                  '优先级',
                  TaskSortType.priority,
                  Icons.flag,
                  provider,
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    provider.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  title: Text(
                    provider.sortAscending ? '升序' : '降序',
                  ),
                  onTap: () {
                    provider.setSortType(provider.sortType);
                    Navigator.pop(context);
                  },
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
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              provider.sortAscending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: Colors.blue,
              size: 20,
            )
          : null,
      onTap: () {
        provider.setSortType(sortType);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, TaskCategory category) {
    final provider = context.watch<TaskProvider>();
    final isSelected = provider.categoryFilter == category;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            category.icon,
            size: 16,
            color: isSelected ? Colors.white : category.color,
          ),
          const SizedBox(width: 4),
          Text(category.label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) {
        provider.setCategoryFilter(isSelected ? null : category);
      },
      selectedColor: category.color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontSize: 13,
      ),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskFormScreen(),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, Task task) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final taskProvider = context.read<TaskProvider>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务 "${task.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true) {
      taskProvider.deleteTask(task.id);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('任务已删除')),
      );
      return true;
    }
    return false;
  }
}
