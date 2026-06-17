import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/tag_provider.dart';
import 'ui/ui.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = task.isCompleted
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: isMultiSelectMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => onSelect?.call(),
                      visualDensity: VisualDensity.compact,
                    )
                  : Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) => onToggle(),
                      activeColor: task.priority.color,
                      visualDensity: VisualDensity.compact,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _DueDateLabel(task: task),
                      ],
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      task.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _TaskMetaRow(task: task),
                  if (task.subtasks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SubtaskProgress(task: task),
                  ],
                ],
              ),
            ),
            if (!isMultiSelectMode) ...[
              const SizedBox(width: AppSpacing.xs),
              _buildActionsMenu(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_TaskCardAction>(
      tooltip: '更多操作',
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
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
                Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: AppSpacing.md),
                Text('删除', style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
        ];
      },
    );
  }
}

class _TaskMetaRow extends StatelessWidget {
  final Task task;

  const _TaskMetaRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        final customTags = task.customTagIds
            .map(tagProvider.getTagById)
            .whereType<CustomTag>()
            .toList();

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            AppInfoPill(
              label: task.category.label,
              color: task.category.color,
              icon: task.category.icon,
            ),
            AppInfoPill(
              label: task.priority.label,
              color: task.priority.color,
              icon: Icons.flag,
              emphasized: task.priority == Priority.high,
            ),
            ...customTags.map(
              (tag) => AppInfoPill(label: tag.name, color: tag.color),
            ),
          ],
        );
      },
    );
  }
}

class _DueDateLabel extends StatelessWidget {
  final Task task;

  const _DueDateLabel({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dueDate = task.dueDate!;
    final isOverdue = _isOverdue(dueDate) && !task.isCompleted;
    final color = isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          DateFormat('M月d日').format(dueDate),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }
}

class _SubtaskProgress extends StatelessWidget {
  final Task task;

  const _SubtaskProgress({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = task.subtasks.where((s) => s.isCompleted).length;
    final total = task.subtasks.length;
    final progress = task.subtaskProgress;
    final color = progress == 1 ? Colors.green : colorScheme.primary;

    return Row(
      children: [
        Text(
          '子任务 $completed/$total',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
