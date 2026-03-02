import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/priority_provider.dart';
import '../providers/ai_mode_provider.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_service.dart';
import 'recycle_bin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final aiModeProvider = context.watch<AiModeProvider>();

          return ListView(
            children: [
              const SizedBox(height: 16),
              // 主题设置
              _buildSectionHeader('外观'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择主题模式'),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('系统'),
                            icon: Icon(Icons.settings_suggest),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('浅色'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('深色'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (selected) {
                          themeProvider.setThemeMode(selected.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('主题色'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: ThemeProvider.availableColors.map((color) {
                          final isSelected = themeProvider.seedColor == color;
                          return GestureDetector(
                            onTap: () => themeProvider.setSeedColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.black, width: 3)
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 通知设置
              _buildSectionHeader('通知'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Consumer<NotificationSettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('每日任务总结'),
                          subtitle: const Text('每天固定时间推送未完成任务总结'),
                          value: settingsProvider.isDailySummaryEnabled,
                          onChanged: (value) async {
                            await settingsProvider.setDailySummaryEnabled(value);
                            if (value) {
                              final taskProvider = context.read<TaskProvider>();
                              final pendingTasks = taskProvider.allTasks.where((t) => !t.isCompleted).toList();
                              final taskTitles = pendingTasks.map((t) => t.title).toList();
                              await NotificationService().scheduleDailySummary(
                                settingsProvider.dailySummaryTime,
                                pendingTasks.length,
                                taskTitles: taskTitles,
                              );
                            } else {
                              await NotificationService().cancelDailySummary();
                            }
                          },
                        ),
                        if (settingsProvider.isDailySummaryEnabled)
                          ListTile(
                            title: const Text('提醒时间'),
                            subtitle: Text(
                              '${settingsProvider.dailySummaryTime.hour.toString().padLeft(2, '0')}:${settingsProvider.dailySummaryTime.minute.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: settingsProvider.dailySummaryTime,
                              );
                              if (time != null) {
                                await settingsProvider.setDailySummaryTime(time);
                                final taskProvider = context.read<TaskProvider>();
                                final pendingTasks = taskProvider.allTasks.where((t) => !t.isCompleted).toList();
                                final taskTitles = pendingTasks.map((t) => t.title).toList();
                                await NotificationService().scheduleDailySummary(
                                  time,
                                  pendingTasks.length,
                                  taskTitles: taskTitles,
                                );
                              }
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // AI 设置
              _buildSectionHeader('AI设置'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('任务解析模式'),
                      const SizedBox(height: 8),
                      Text(
                        aiModeProvider.mode == AiParseMode.remoteFirst
                            ? '远程优先（远程失败时自动回退本地解析）'
                            : '本地优先（完全使用本地规则解析）',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<AiParseMode>(
                        segments: const [
                          ButtonSegment(
                            value: AiParseMode.remoteFirst,
                            label: Text('远程优先'),
                            icon: Icon(Icons.cloud_outlined),
                          ),
                          ButtonSegment(
                            value: AiParseMode.localFirst,
                            label: Text('本地优先'),
                            icon: Icon(Icons.offline_bolt_outlined),
                          ),
                        ],
                        selected: {aiModeProvider.mode},
                        onSelectionChanged: (selected) {
                          aiModeProvider.setMode(selected.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 数据管理
              _buildSectionHeader('数据管理'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('导出任务'),
                      subtitle: const Text('备份任务数据到文件'),
                      onTap: () => _exportTasks(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('导入任务'),
                      subtitle: const Text('从文件恢复任务'),
                      onTap: () => _importTasks(context),
                    ),
                    Consumer<TaskProvider>(
                      builder: (context, provider, child) {
                        final count = provider.deletedTasks.length;
                        return ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('回收站'),
                          subtitle: Text(count > 0 ? '$count 个已删除任务' : '已删除的任务'),
                          trailing: count > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecycleBinScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 标签管理
              _buildSectionHeader('标签管理'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Consumer<TagProvider>(
                  builder: (context, tagProvider, child) {
                    final List<Widget> tagItems = tagProvider.tags.map<Widget>((tag) => ListTile(
                              leading: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: tag.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text(tag.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDeleteTag(context, tagProvider, tag.id, tag.name),
                              ),
                            )).toList();
                    tagItems.add(ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('添加标签'),
                      onTap: () => _showAddTagDialog(context),
                    ));
                    return Column(children: tagItems);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 优先级管理
              _buildSectionHeader('优先级管理'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Consumer<PriorityProvider>(
                  builder: (context, priorityProvider, child) {
                    final customPriorities = priorityProvider.customPriorities;
                    final List<Widget> priorityItems = [
                      // 内置优先级显示
                      const ListTile(
                        leading: Icon(Icons.flag, color: Colors.red),
                        title: Text('高'),
                        subtitle: Text('内置优先级'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.flag, color: Colors.orange),
                        title: Text('中'),
                        subtitle: Text('内置优先级'),
                      ),
                      const ListTile(
                        leading: Icon(Icons.flag, color: Colors.green),
                        title: Text('低'),
                        subtitle: Text('内置优先级'),
                      ),
                    ];
                    // 添加自定义优先级
                    for (final priority in customPriorities) {
                      priorityItems.add(ListTile(
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: priority.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(priority.name),
                        subtitle: Text('自定义优先级'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDeletePriority(context, priorityProvider, priority.id, priority.name),
                        ),
                      ));
                    }
                    priorityItems.add(ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('添加自定义优先级'),
                      onTap: () => _showAddPriorityDialog(context),
                    ));
                    return Column(children: priorityItems);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 关于
              _buildSectionHeader('关于'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('版本'),
                      trailing: const Text('1.0.0'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.smart_toy_outlined),
                      title: const Text('AI助手'),
                      subtitle: const Text('内置智能任务管理'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _exportTasks(BuildContext context) async {
    final provider = context.read<TaskProvider>();
    final filePath = await provider.exportTaskBackup();

    if (filePath != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出成功')),
      );
      // 分享文件
      await Share.shareXFiles([XFile(filePath)], text: 'AiTODO 任务备份');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导出失败')),
      );
    }
  }

  Future<void> _importTasks(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (!context.mounted) return;

    if (result != null && result.files.single.path != null) {
      final importedBundle =
          await context.read<TaskProvider>().importTaskBackup(result.files.single.path!);
      final importedTasks = importedBundle?.tasks;
      final importedDeletedTasks = importedBundle?.deletedTasks ?? const [];

      if (importedTasks != null && context.mounted) {
        final provider = context.read<TaskProvider>();
        // 询问用户是合并还是替换
        final choice = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('导入方式'),
            content: Text('找到 ${importedTasks.length} 个任务，请选择导入方式'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'merge'),
                child: const Text('合并'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'replace'),
                child: const Text('替换'),
              ),
            ],
          ),
        );

        if (choice == 'merge' || choice == 'replace') {
          if (choice == 'replace') {
            // 替换现有任务并清空回收站，保留导入数据原字段。
            await provider.replaceAllTasks(
              importedTasks,
              clearDeletedTasks: importedDeletedTasks.isEmpty,
              deletedTasks: importedDeletedTasks,
            );
          } else {
            // 合并任务，若ID冲突则使用导入版本覆盖。
            await provider.mergeTasks(importedTasks);
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('成功导入 ${importedTasks.length} 个任务')),
            );
          }
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入失败：文件格式错误')),
        );
      }
    }
  }

  void _showAddTagDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加标签'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '标签名称',
                  hintText: '例如：重要',
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.orange,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.pink,
                  Colors.teal,
                  Colors.indigo,
                ].map((color) => GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<TagProvider>().addTag(
                        nameController.text.trim(),
                        selectedColor,
                      );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTag(BuildContext context, TagProvider provider, String tagId, String tagName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签 "$tagName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTag(tagId);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddPriorityDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    int selectedLevel = 2;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加自定义优先级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '优先级名称',
                  hintText: '例如：紧急重要',
                ),
              ),
              const SizedBox(height: 16),
              const Text('选择颜色'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.orange,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.pink,
                  Colors.teal,
                  Colors.indigo,
                ].map((color) => GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('选择优先级等级'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('低')),
                  ButtonSegment(value: 2, label: Text('中')),
                  ButtonSegment(value: 3, label: Text('高')),
                ],
                selected: {selectedLevel},
                onSelectionChanged: (selected) {
                  setState(() => selectedLevel = selected.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  context.read<PriorityProvider>().addPriority(
                        nameController.text.trim(),
                        selectedColor,
                        selectedLevel,
                      );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePriority(BuildContext context, PriorityProvider provider, String priorityId, String priorityName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除优先级'),
        content: Text('确定要删除优先级 "$priorityName" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePriority(priorityId);
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
