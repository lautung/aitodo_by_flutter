import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/ui/ui.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadDeletedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final deletedTasks = provider.deletedTasks;

        return AppPageScaffold(
          title: '回收站',
          subtitle: deletedTasks.isEmpty
              ? '删除的任务会先保存在这里'
              : '${deletedTasks.length} 个任务等待处理',
          leadingIcon: Icons.delete_outline,
          actions: [
            if (deletedTasks.isNotEmpty)
              IconButton.filledTonal(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: '清空回收站',
                onPressed: () => _showClearDialog(context),
              ),
          ],
          child: deletedTasks.isEmpty
              ? const AppEmptyState(
                  icon: Icons.delete_outline,
                  title: '回收站为空',
                  message: '删除的任务会在这里显示，可以恢复或永久删除。',
                )
              : AppSurface(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: deletedTasks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final task = deletedTasks[index];
                      return _buildTaskItem(context, task);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    final colorScheme = Theme.of(context).colorScheme;

    return AppListItem(
      icon: task.category.icon,
      iconColor: task.category.color,
      title: task.title,
      subtitle: '创建于 ${dateFormat.format(task.createdAt)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复',
            color: colorScheme.primary,
            onPressed: () {
              context.read<TaskProvider>().restoreTask(task.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('任务已恢复')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            tooltip: '永久删除',
            color: colorScheme.error,
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id, permanent: true);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('任务已永久删除')));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: '清空回收站',
      message: '确定要永久删除所有回收站中的任务吗？此操作不可恢复。',
      confirmLabel: '清空',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<TaskProvider>().clearDeletedTasks();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('回收站已清空')));
  }
}
