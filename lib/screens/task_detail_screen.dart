import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../providers/task_provider.dart';
import '../widgets/ui/ui.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    final newSubtask = SubTask(title: text);
    final updatedSubtasks = List<SubTask>.from(_task.subtasks)..add(newSubtask);

    setState(() {
      _task = _task.copyWith(subtasks: updatedSubtasks);
    });

    _subtaskController.clear();
    _saveTask();
  }

  void _toggleSubtask(String subtaskId) {
    final updatedSubtasks = _task.subtasks.map((s) {
      if (s.id == subtaskId) {
        return s.copyWith(isCompleted: !s.isCompleted);
      }
      return s;
    }).toList();

    setState(() {
      _task = _task.copyWith(subtasks: updatedSubtasks);
    });

    _saveTask();
  }

  void _deleteSubtask(String subtaskId) {
    final updatedSubtasks = _task.subtasks
        .where((s) => s.id != subtaskId)
        .toList();

    setState(() {
      _task = _task.copyWith(subtasks: updatedSubtasks);
    });

    _saveTask();
  }

  void _saveTask() {
    context.read<TaskProvider>().updateTask(_task);
  }

  void _shareTask() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final buffer = StringBuffer();

    buffer.writeln('【任务分享】');
    buffer.writeln('');
    buffer.writeln('标题: ${_task.title}');
    if (_task.description != null && _task.description!.isNotEmpty) {
      buffer.writeln('描述: ${_task.description}');
    }
    buffer.writeln('优先级: ${_task.priority.label}');
    buffer.writeln('分类: ${_task.category.label}');
    if (_task.dueDate != null) {
      buffer.writeln('截止日期: ${dateFormat.format(_task.dueDate!)}');
    }
    buffer.writeln('状态: ${_task.isCompleted ? "已完成" : "进行中"}');
    if (_task.subtasks.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('子任务:');
      for (final subtask in _task.subtasks) {
        buffer.writeln('${subtask.isCompleted ? "☑" : "☐"} ${subtask.title}');
      }
    }
    buffer.writeln('');
    buffer.writeln('—来自 AiTODO');

    Share.share(buffer.toString());
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: _task)),
    );
    if (!mounted) return;
    final latestTask = context.read<TaskProvider>().getTaskById(_task.id);
    if (latestTask != null) {
      setState(() {
        _task = latestTask;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return AppPageScaffold(
      title: '任务详情',
      subtitle: '${_task.priority.label} · ${_task.category.label}',
      leadingIcon: _task.category.icon,
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.share_outlined),
          tooltip: '分享',
          onPressed: _shareTask,
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '编辑',
          onPressed: _navigateToEdit,
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务标题和状态
            AppSurface(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _task.isCompleted,
                          onChanged: (_) async {
                            final provider = context.read<TaskProvider>();
                            if (!_task.isCompleted &&
                                !provider.canCompleteTask(_task.id)) {
                              // 显示前置任务未完成的提示
                              final prereqs = provider.getPrerequisiteTasks(
                                _task.id,
                              );
                              final pendingPrereqs = prereqs
                                  .where((t) => !t.isCompleted)
                                  .toList();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '请先完成前置任务: ${pendingPrereqs.map((t) => t.title).join(", ")}',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            await provider.toggleTaskCompletion(_task.id);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            _task.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: _task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_task.description != null &&
                        _task.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: Text(
                          _task.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 任务信息
            AppSurface(
              child: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.flag,
                      '优先级',
                      _task.priority.label,
                      _task.priority.color,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.category,
                      '分类',
                      _task.category.label,
                      _task.category.color,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.calendar_today,
                      '截止日期',
                      _task.dueDate != null
                          ? dateFormat.format(_task.dueDate!)
                          : '未设置',
                      null,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.repeat,
                      '重复',
                      _task.repeatType.label,
                      null,
                    ),
                    if (_task.prerequisiteIds.isNotEmpty) ...[
                      const Divider(),
                      _buildPrerequisiteRow(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 子任务列表
            AppSectionHeader(
              title: '子任务',
              count: _task.subtasks.isEmpty ? null : _task.subtasks.length,
              subtitle: _task.subtasks.isEmpty
                  ? null
                  : '${_task.subtasks.where((s) => s.isCompleted).length} 已完成',
            ),
            const SizedBox(height: 8),

            // 进度条
            if (_task.subtasks.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _task.subtaskProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _task.subtaskProgress == 1.0 ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 添加子任务
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: InputDecoration(
                      hintText: '添加子任务...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 子任务列表
            if (_task.subtasks.isEmpty)
              const AppSurface(
                child: AppEmptyState(
                  icon: Icons.checklist,
                  title: '暂无子任务',
                  message: '把复杂任务拆小后，可以在这里逐项完成。',
                ),
              )
            else
              ...(_task.subtasks.map((subtask) => _buildSubtaskItem(subtask))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color? color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteRow() {
    final provider = context.read<TaskProvider>();
    final prereqs = provider.getPrerequisiteTasks(_task.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text('前置任务', style: TextStyle(color: Colors.grey[600])),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _showPrerequisiteSelector(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (prereqs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...prereqs.map(
              (prereq) => Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      prereq.isCompleted ? Icons.check_circle : Icons.pending,
                      size: 16,
                      color: prereq.isCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        prereq.title,
                        style: TextStyle(
                          decoration: prereq.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: prereq.isCompleted ? Colors.grey : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _removePrerequisite(prereq.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPrerequisiteSelector() {
    final provider = context.read<TaskProvider>();
    final allTasks = provider.allTasks;
    // 过滤掉自己和非已完成的任务
    final availableTasks = allTasks
        .where((t) => t.id != _task.id && !_task.prerequisiteIds.contains(t.id))
        .toList();

    showAppBottomSheet(
      context: context,
      title: '选择前置任务',
      subtitle: '完成这些任务后才能完成当前任务',
      child: availableTasks.isEmpty
          ? const AppEmptyState(
              icon: Icons.link_off,
              title: '没有可用的任务',
              message: '可选择的前置任务会显示在这里。',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: availableTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = availableTasks[index];
                return AppListItem(
                  icon: task.isCompleted
                      ? Icons.check_circle_outline
                      : Icons.pending_outlined,
                  iconColor: task.isCompleted ? Colors.green : Colors.orange,
                  title: task.title,
                  subtitle: task.description,
                  onTap: () {
                    _addPrerequisite(task.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }

  void _addPrerequisite(String prerequisiteId) {
    final updatedPrerequisites = List<String>.from(_task.prerequisiteIds)
      ..add(prerequisiteId);
    setState(() {
      _task = _task.copyWith(prerequisiteIds: updatedPrerequisites);
    });
    _saveTask();
  }

  void _removePrerequisite(String prerequisiteId) {
    final updatedPrerequisites = _task.prerequisiteIds
        .where((id) => id != prerequisiteId)
        .toList();
    setState(() {
      _task = _task.copyWith(prerequisiteIds: updatedPrerequisites);
    });
    _saveTask();
  }

  Widget _buildSubtaskItem(SubTask subtask) {
    return Dismissible(
      key: Key(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteSubtask(subtask.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppSurface(
          padding: EdgeInsets.zero,
          child: AppListItem(
            leading: Checkbox(
              value: subtask.isCompleted,
              onChanged: (_) => _toggleSubtask(subtask.id),
            ),
            title: subtask.title,
            titleStyle: TextStyle(
              decoration: subtask.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: subtask.isCompleted
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
              fontWeight: FontWeight.w700,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _deleteSubtask(subtask.id),
            ),
          ),
        ),
      ),
    );
  }
}
