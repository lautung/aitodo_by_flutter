import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    // 加载回收站数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadDeletedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              if (provider.deletedTasks.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: '清空回收站',
                onPressed: () => _showClearDialog(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final deletedTasks = provider.deletedTasks;

          if (deletedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '回收站为空',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '删除的任务会在这里显示',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: deletedTasks.length,
            itemBuilder: (context, index) {
              final task = deletedTasks[index];
              return _buildTaskItem(context, task);
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final dateFormat = DateFormat('MM/dd HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          task.category.icon,
          color: task.category.color,
        ),
        title: Text(
          task.title,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        subtitle: Text(
          '创建于 ${dateFormat.format(task.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: '恢复',
              onPressed: () {
                context.read<TaskProvider>().restoreTask(task.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('任务已恢复')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: '永久删除',
              onPressed: () {
                context.read<TaskProvider>().deleteTask(task.id, permanent: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('任务已永久删除')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要永久删除所有回收站中的任务吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().clearDeletedTasks();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('回收站已清空')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
