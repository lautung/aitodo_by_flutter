import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/priority_provider.dart';
import '../providers/ai_mode_provider.dart';
import '../services/ai_dispatcher_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  Priority _priority = Priority.medium;
  TaskCategory _category = TaskCategory.other;
  RepeatType _repeatType = RepeatType.none;
  bool _hasReminder = false;
  DateTime? _reminderTime;  // 自定义提醒时间
  List<String> _selectedTagIds = [];

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    if (widget.task != null) {
      _dueDate = widget.task!.dueDate;
      _priority = widget.task!.priority;
      _category = widget.task!.category;
      _repeatType = widget.task!.repeatType;
      _hasReminder = widget.task!.reminderTime != null;
      _reminderTime = widget.task!.reminderTime;  // 加载已有提醒时间
      _selectedTagIds = List<String>.from(widget.task!.customTagIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑任务' : '新建任务'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              '保存',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field with AI button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '任务标题 *',
                      hintText: '请输入任务标题，或直接输入完整描述',
                      prefixIcon: const Icon(Icons.title),
                      border: const OutlineInputBorder(),
                      suffixIcon: _titleController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.auto_awesome),
                              tooltip: 'AI智能识别',
                              onPressed: _parseWithAI,
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入任务标题';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // AI tip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '试试输入"下周三完成报告"或"紧急的工作任务"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '任务描述',
                hintText: '请输入任务描述（可选）',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Due date
            Text(
              '截止日期',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? dateFormat.format(_dueDate!)
                          : '选择日期（可选）',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dueDate != null ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _dueDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Reminder settings
            Text(
              '提醒设置',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            // Reminder switch
            SwitchListTile(
              title: const Text('启用提醒'),
              subtitle: Text(
                _dueDate != null
                    ? (_hasReminder ? '已开启' : '未开启')
                    : '请先设置截止日期',
              ),
              value: _hasReminder && _dueDate != null,
              onChanged: _dueDate != null
                  ? (value) {
                      setState(() {
                        _hasReminder = value;
                        // 如果开启提醒且没有设置过提醒时间，默认设置为截止前15分钟
                        if (value && _reminderTime == null && _dueDate != null) {
                          _reminderTime = _dueDate!.subtract(const Duration(minutes: 15));
                        }
                      });
                    }
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
            // Reminder time picker (shown when reminder is enabled)
            if (_hasReminder && _dueDate != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectReminderTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '提醒时间',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _reminderTime != null
                                  ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_reminderTime!)
                                  : '选择时间',
                              style: TextStyle(
                                fontSize: 16,
                                color: _reminderTime != null ? Colors.black87 : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Priority
            Text(
              '优先级',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Consumer<PriorityProvider>(
              builder: (context, priorityProvider, child) {
                final priorities = priorityProvider.allPriorities;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: priorities.map((priority) {
                    final isSelected = _priority == priority.toPriority();
                    return ChoiceChip(
                      label: Text(priority.name),
                      selected: isSelected,
                      selectedColor: priority.color.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? priority.color : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _priority = priority.toPriority();
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Category
            Text(
              '分类',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskCategory.values.map((category) {
                final isSelected = _category == category;
                return ChoiceChip(
                  avatar: Icon(
                    category.icon,
                    size: 18,
                    color: isSelected ? category.color : Colors.grey[600],
                  ),
                  label: Text(category.label),
                  selected: isSelected,
                  selectedColor: category.color.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? category.color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _category = category;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Repeat
            Text(
              '重复',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RepeatType.values.map((repeat) {
                final isSelected = _repeatType == repeat;
                return ChoiceChip(
                  label: Text(repeat.label),
                  selected: isSelected,
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _repeatType = repeat;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Custom tags
            Text(
              '标签',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Consumer<TagProvider>(
              builder: (context, tagProvider, child) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tagProvider.tags.map<Widget>((tag) {
                    final isSelected = _selectedTagIds.contains(tag.id);
                    return FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      selectedColor: tag.color.withValues(alpha: 0.3),
                      checkmarkColor: tag.color,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEditing ? '保存修改' : '创建任务',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _parseWithAI() async {
    final text = _titleController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入任务内容')),
      );
      return;
    }

    final preferRemote = context.read<AiModeProvider>().preferRemote;
    final parsed = await AiDispatcherService().parseTask(
      text,
      preferRemote: preferRemote,
    );

    if (!mounted) return;

    setState(() {
      // 更新标题
      _titleController.text = parsed.title;

      // 更新描述
      if (parsed.description != null && parsed.description!.isNotEmpty) {
        _descriptionController.text = parsed.description!;
      }

      // 更新截止日期
      if (parsed.dueDate != null) {
        _dueDate = parsed.dueDate;
      }

      // 更新优先级
      if (parsed.priority != null) {
        _priority = parsed.priority!;
      }

      // 更新分类
      if (parsed.suggestedCategory != null) {
        _category = parsed.suggestedCategory!;
      }
    });

    // 显示解析结果
    final results = <String>[];
    if (parsed.hasDate) results.add('日期');
    if (parsed.hasPriority) results.add('优先级');
    if (parsed.hasCategory) results.add('分类');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          results.isEmpty
              ? '已解析任务内容'
              : '已智能识别：${results.join("、")}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    // 先选择日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: _dueDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    // 再选择时间
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime != null
          ? TimeOfDay.fromDateTime(_reminderTime!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _reminderTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
          0,
        );
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<TaskProvider>();

    // 使用自定义提醒时间（如果已设置），否则为 null
    DateTime? reminderTime;
    if (_hasReminder && _dueDate != null) {
      reminderTime = _reminderTime;
    }

    if (isEditing) {
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
        repeatType: _repeatType,
        reminderTime: reminderTime,
        customTagIds: _selectedTagIds,
      );
      await provider.updateTask(updatedTask);
    } else {
      await provider.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
        repeatType: _repeatType,
        reminderTime: reminderTime,
        customTagIds: _selectedTagIds,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? '任务已更新' : '任务已创建'),
      ),
    );
  }
}
