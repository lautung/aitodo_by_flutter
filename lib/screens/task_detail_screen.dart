import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../providers/task_provider.dart';
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
    final updatedSubtasks = _task.subtasks.where((s) => s.id != subtaskId).toList();

    setState(() {
      _task = _task.copyWith(subtasks: updatedSubtasks);
    });

    _saveTask();
  }

  void _saveTask() {
    context.read<TaskProvider>().updateTask(_task);
  }

  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: _task),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务标题和状态
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _task.isCompleted,
                          onChanged: (_) {
                            context.read<TaskProvider>().toggleTaskCompletion(_task.id);
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            _task.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: _task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_task.description != null && _task.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: Text(
                          _task.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                      _task.dueDate != null ? dateFormat.format(_task.dueDate!) : '未设置',
                      null,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.repeat,
                      '重复',
                      _task.repeatType.label,
                      null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 子任务列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '子任务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_task.subtasks.isNotEmpty)
                  Text(
                    '${_task.subtasks.where((s) => s.isCompleted).length}/${_task.subtasks.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
              ],
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '暂无子任务',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_task.subtasks.map((subtask) => _buildSubtaskItem(subtask))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: subtask.isCompleted,
            onChanged: (_) => _toggleSubtask(subtask.id),
          ),
          title: Text(
            subtask.title,
            style: TextStyle(
              decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
              color: subtask.isCompleted ? Colors.grey : null,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _deleteSubtask(subtask.id),
          ),
        ),
      ),
    );
  }
}
