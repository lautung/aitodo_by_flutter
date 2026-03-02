import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/tag_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Future<bool> Function()? onDeleteConfirm;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final GlobalKey<TaskCardState>? swipeKey;
  final VoidCallback? onCollapse;
  final VoidCallback? onExpand;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onDeleteConfirm,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelect,
    this.swipeKey,
    this.onCollapse,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final card = _SwipeToDeleteCard(
      key: swipeKey,
      task: task,
      onTap: onTap,
      onToggle: onToggle,
      onDelete: onDelete,
      onDeleteConfirm: onDeleteConfirm,
      isMultiSelectMode: isMultiSelectMode,
      isSelected: isSelected,
      onSelect: onSelect,
      dateFormat: dateFormat,
      onCollapse: onCollapse,
      onExpand: onExpand,
    );
    return card;
  }
}

class _SwipeToDeleteCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Future<bool> Function()? onDeleteConfirm;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final DateFormat dateFormat;
  final VoidCallback? onCollapse;
  final VoidCallback? onExpand;

  const _SwipeToDeleteCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.onDeleteConfirm,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelect,
    required this.dateFormat,
    this.onCollapse,
    this.onExpand,
  });

  @override
  State<_SwipeToDeleteCard> createState() => TaskCardState();
}

class TaskCardState extends State<_SwipeToDeleteCard>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  static const double _maxDragExtent = 60;
  static const double _dismissThreshold = 0.35;
  bool _isExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  double get _progress => (_dragExtent.abs() / _maxDragExtent).clamp(0.0, 1.0);
  bool get _shouldDismiss => _dragExtent.abs() >= _maxDragExtent * _dismissThreshold;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animation.addListener(() {
      setState(() {
        _dragExtent = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent.abs() > _maxDragExtent) {
        _dragExtent = -_maxDragExtent;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_shouldDismiss) {
      _isExpanded = true;
      _animateToPosition(-_maxDragExtent);
      widget.onExpand?.call();
    } else {
      _isExpanded = false;
      _animateToPosition(0);
    }
  }

  void _handleCardTap() {
    if (_isExpanded) {
      _isExpanded = false;
      _animateToPosition(0);
    } else {
      widget.onTap();
    }
  }

  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      _animateToPosition(0);
      widget.onCollapse?.call();
    }
  }

  void _handleDeleteTap() {
    widget.onDelete();
  }

  void _animateToPosition(double target) {
    _animation = Tween<double>(
      begin: _dragExtent,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward(from: 0);
  }

  bool _isDueOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today) && !widget.task.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final bool showDeleteButton = _shouldDismiss;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 15),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showDeleteButton ? 1.0 : _progress,
              child: Transform.scale(
                scale: 0.5 + (_progress * 0.5),
                child: GestureDetector(
                  onTap: showDeleteButton ? _handleDeleteTap : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onTap: _handleCardTap,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: _buildCardContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final dateFormat = widget.dateFormat;
    final task = widget.task;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: task.priority.color,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              if (widget.isMultiSelectMode)
                Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onSelect?.call(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => widget.onToggle(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: task.priority.color,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildTagsRow(context, dateFormat),
                    // 子任务进度
                    if (task.subtasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSubtaskProgress(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskProgress() {
    final task = widget.task;
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
    final task = widget.task;

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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  color: _isDueOverdue(task.dueDate!) ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 2),
                Text(
                  dateFormat.format(task.dueDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isDueOverdue(task.dueDate!) ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
