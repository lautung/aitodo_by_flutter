import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/ai_mode_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_dispatcher_service.dart';
import '../services/chat_storage_service.dart';
import '../widgets/ui/ui.dart';

/// 聊天消息模型（用于UI）
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Task? createdTask;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.createdTask,
  });
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final savedMessages = await ChatStorageService.loadMessages();

    if (savedMessages.isEmpty) {
      // 添加欢迎消息
      _messages.add(
        ChatMessage(
          content: _welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      // 加载保存的消息
      _messages.addAll(
        savedMessages.map(
          (msg) => ChatMessage(
            content: msg.content,
            isUser: msg.isUser,
            timestamp: msg.timestamp,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    final now = DateTime.now();

    setState(() {
      _isProcessing = true;
      _messages.add(ChatMessage(content: text, isUser: true, timestamp: now));
      _inputController.clear();
    });

    // 保存用户消息和处理消息并行执行
    await Future.wait([
      ChatStorageService.addMessage(
        StoredChatMessage(
          id: now.millisecondsSinceEpoch.toString(),
          content: text,
          isUser: true,
          timestamp: now,
        ),
      ),
      _processMessage(text),
    ]);

    // 滚动到底部
    _scrollToBottom();
  }

  Future<void> _processMessage(String text) async {
    final lowerText = text.toLowerCase();
    final provider = context.read<TaskProvider>();

    String response;
    Task? createdTask;

    // 定义任务相关的命令关键词
    final taskQueryKeywords = [
      '有多少',
      '还有多少',
      '未完成',
      '已完成',
      '完成率',
      '今天',
      '明天',
      '本周',
      '显示',
      '查看',
      '列表',
      '删除',
      '完成',
      '待办',
      '任务',
      'todo',
    ];

    // 检查是否是查询任务状态的命令
    bool isTaskQuery = taskQueryKeywords.any((k) => lowerText.contains(k));

    if (lowerText.contains('有多少') ||
        lowerText.contains('还有多少') ||
        lowerText.contains('未完成')) {
      final activeCount = provider.activeTasks;
      final totalCount = provider.totalTasks;
      response = '你当前有 $activeCount 个未完成的任务，共 $totalCount 个任务。';
    } else if (lowerText.contains('今天') &&
        (lowerText.contains('要') ||
            lowerText.contains('需要') ||
            lowerText.contains('截止'))) {
      final today = DateTime.now();
      final todayTasks = provider.tasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == today.year &&
            t.dueDate!.month == today.month &&
            t.dueDate!.day == today.day &&
            !t.isCompleted;
      }).toList();
      if (todayTasks.isEmpty) {
        response = '今天没有待完成的任务哦～';
      } else {
        response = '今天有 ${todayTasks.length} 个任务要完成：\n';
        for (final task in todayTasks.take(5)) {
          response += '• ${task.title}\n';
        }
        if (todayTasks.length > 5) {
          response += '...还有 ${todayTasks.length - 5} 个';
        }
      }
    } else if (lowerText.contains('已完成') && !lowerText.contains('完成率')) {
      final completedCount = provider.completedTasks;
      response = '你已完成 $completedCount 个任务，继续加油！';
    } else if (lowerText.contains('完成率')) {
      final rate = (provider.completionRate * 100).toStringAsFixed(1);
      response = '当前任务完成率为 $rate%';
    } else if (lowerText.contains('显示') ||
        lowerText.contains('查看') ||
        lowerText.contains('列表')) {
      final tasks = provider.tasks.take(5).toList();
      if (tasks.isEmpty) {
        response = '当前没有任务哦～';
      } else {
        response = '以下是当前任务：\n';
        for (final task in tasks) {
          final status = task.isCompleted ? '✅' : '⬜';
          response += '$status ${task.title}\n';
        }
        if (provider.totalTasks > 5) {
          response += '\n...还有 ${provider.totalTasks - 5} 个任务';
        }
      }
    } else if (lowerText.contains('你好') ||
        lowerText.contains('hi') ||
        lowerText.contains('hello')) {
      response =
          '你好！我是AiTODO助手，可以帮你管理任务哦～\n\n可以这样说：\n• "下周三完成报告"\n• "我有多少未完成的任务"\n• "显示任务列表"';
    } else if (!isTaskQuery &&
        !lowerText.contains('创建') &&
        !lowerText.contains('添加') &&
        !lowerText.contains('帮我') &&
        !lowerText.contains('任务')) {
      // 非任务相关且没有明确创建意图的消息，回复不知道
      response =
          '抱歉，我不太明白你的意思 😅\n\n我可以帮你：\n• 创建任务："下周三完成报告"\n• 查询状态："我有多少未完成的任务"\n• 查看列表："显示所有任务"';
    } else {
      // 尝试创建任务
      final preferRemote = context.read<AiModeProvider>().preferRemote;
      final parsed = await AiDispatcherService().parseTask(
        text,
        preferRemote: preferRemote,
      );

      if (parsed.title.isEmpty) {
        response =
            '抱歉，我没能理解你的意思 😅\n\n你可以：\n• 直接输入任务描述创建任务，如"下周三完成报告"\n• 输入"显示任务"查看现有任务';
      } else {
        createdTask = await provider.addTask(
          title: parsed.title,
          description: parsed.description,
          dueDate: parsed.dueDate,
          priority: parsed.priority ?? Priority.medium,
          category: parsed.suggestedCategory ?? TaskCategory.other,
        );

        response = '好的，我已经帮你创建了任务：\n📝 ${parsed.title}';
        if (parsed.hasDate) {
          final dateStr = '${parsed.dueDate!.month}月${parsed.dueDate!.day}日';
          response += '\n📅 截止日期：$dateStr';
        }
        if (parsed.hasPriority) {
          response += '\n⭐ 优先级：${parsed.priority!.label}';
        }
        if (parsed.hasCategory) {
          response += '\n📂 分类：${parsed.suggestedCategory!.label}';
        }
      }
    }

    // 添加AI回复
    final aiNow = DateTime.now();
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            content: response,
            isUser: false,
            timestamp: aiNow,
            createdTask: createdTask,
          ),
        );
        _isProcessing = false;
      });
    }

    // 保存AI回复
    await ChatStorageService.addMessage(
      StoredChatMessage(
        id: aiNow.millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: aiNow,
      ),
    );

    // 滚动到底部
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  static const String _welcomeMessage =
      '你好！我是AiTODO助手，可以用自然语言帮我创建任务哦～\n\n比如：\n• "下周三完成项目报告"\n• "帮我创建一个紧急的工作任务"\n• "明天有个会议"\n\n也可以查询任务状态，比如：\n• "我有多少未完成的任务"\n• "显示今天要完成的任务"';

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          content: _welcomeMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    ChatStorageService.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'AI助手',
      subtitle: '用自然语言创建、查询和整理任务',
      leadingIcon: Icons.smart_toy_outlined,
      actions: [
        IconButton.filledTonal(
          icon: const Icon(Icons.refresh),
          tooltip: '清空聊天',
          onPressed: () async {
            final confirmed = await showAppConfirmDialog(
              context: context,
              title: '清空聊天',
              message: '确定要清空所有聊天记录吗？',
              confirmLabel: '清空',
              destructive: true,
            );
            if (confirmed == true) _clearChat();
          },
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: AppSurface(
                    padding: EdgeInsets.zero,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isProcessing) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppCommandField(
                  controller: _inputController,
                  hintText: '输入任务描述...',
                  leadingIcon: Icons.auto_awesome,
                  actionIcon: Icons.send,
                  actionTooltip: '发送',
                  actionEnabled: !_isProcessing,
                  onSubmitted: (_) => _sendMessage(),
                  onActionPressed: _sendMessage,
                  onClear: _inputController.clear,
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = message.isUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    final foreground = message.isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(AppRadii.md).copyWith(
                      bottomRight: message.isUser
                          ? const Radius.circular(4)
                          : null,
                      bottomLeft: !message.isUser
                          ? const Radius.circular(4)
                          : null,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}
