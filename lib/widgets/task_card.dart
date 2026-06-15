import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/tag_provider.dart';

enum _TaskCardAction { delete }

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final Future<bool> Function() onDeleteConfirm;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDeleteConfirm,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: task.priority.color, width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (isMultiSelectMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => onSelect?.call(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      else
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) => onToggle(),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: task.priority.color,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTaskContent(context, dateFormat)),
                    ],
                  ),
                ),
              ),
            ),
            if (!isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _buildActionsMenu(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
          ),
        ),
        if (task.description != null && task.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _buildTagsRow(context, dateFormat),
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSubtaskProgress(),
        ],
      ],
    );
  }

  Widget _buildActionsMenu() {
    return PopupMenuButton<_TaskCardAction>(
      tooltip: '更多操作',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case _TaskCardAction.delete:
            onDeleteConfirm();
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _TaskCardAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                const SizedBox(width: 12),
                Text('删除', style: TextStyle(color: Colors.red[600])),
              ],
            ),
          ),
        ];
      },
    );
  }

  bool _isDueOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today) && !task.isCompleted;
  }

  Widget _buildSubtaskProgress() {
    final completed = task.subtasks.where((s) => s.isCompleted).length;
    final total = task.subtasks.length;
    final progress = task.subtaskProgress;

    return Row(
      children: [
        Icon(
          Icons.checklist,
          size: 14,
          color: progress == 1.0 ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blue,
              ),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: 11,
            color: progress == 1.0 ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow(BuildContext context, DateFormat dateFormat) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: task.category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(task.category.icon, size: 12, color: task.category.color),
              const SizedBox(width: 4),
              Text(
                task.category.label,
                style: TextStyle(fontSize: 11, color: task.category.color),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: task.priority.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag, size: 12, color: task.priority.color),
              const SizedBox(width: 4),
              Text(
                task.priority.label,
                style: TextStyle(
                  fontSize: 11,
                  color: task.priority.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (task.customTagIds.isNotEmpty)
          Consumer<TagProvider>(
            builder: (context, tagProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: task.customTagIds.map<Widget>((tagId) {
                  final tag = tagProvider.getTagById(tagId);
                  if (tag == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tag.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tag.color.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: tag.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (task.dueDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _isDueOverdue(task.dueDate!)
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: _isDueOverdue(task.dueDate!)
                      ? Colors.red
                      : Colors.grey,
                ),
                const SizedBox(width: 2),
                Text(
                  dateFormat.format(task.dueDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDueOverdue(task.dueDate!)
                        ? Colors.red
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
