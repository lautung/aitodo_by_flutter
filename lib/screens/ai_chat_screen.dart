import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/ai_mode_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_dispatcher_service.dart';
import '../services/chat_storage_service.dart';

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
      _messages.add(ChatMessage(
        content: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } else {
      // 加载保存的消息
      _messages.addAll(savedMessages.map((msg) => ChatMessage(
        content: msg.content,
        isUser: msg.isUser,
        timestamp: msg.timestamp,
      )));
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
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: now,
      ));
      _inputController.clear();
    });

    // 保存用户消息和处理消息并行执行
    await Future.wait([
      ChatStorageService.addMessage(StoredChatMessage(
        id: now.millisecondsSinceEpoch.toString(),
        content: text,
        isUser: true,
        timestamp: now,
      )),
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
      '有多少', '还有多少', '未完成', '已完成', '完成率',
      '今天', '明天', '本周', '显示', '查看', '列表',
      '删除', '完成', '待办', '任务', 'todo',
    ];

    // 检查是否是查询任务状态的命令
    bool isTaskQuery = taskQueryKeywords.any((k) => lowerText.contains(k));

    if (lowerText.contains('有多少') || lowerText.contains('还有多少') || lowerText.contains('未完成')) {
      final activeCount = provider.activeTasks;
      final totalCount = provider.totalTasks;
      response = '你当前有 $activeCount 个未完成的任务，共 $totalCount 个任务。';
    } else if (lowerText.contains('今天') && (lowerText.contains('要') || lowerText.contains('需要') || lowerText.contains('截止'))) {
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
    } else if (lowerText.contains('显示') || lowerText.contains('查看') || lowerText.contains('列表')) {
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
    } else if (lowerText.contains('你好') || lowerText.contains('hi') || lowerText.contains('hello')) {
      response = '你好！我是AiTODO助手，可以帮你管理任务哦～\n\n可以这样说：\n• "下周三完成报告"\n• "我有多少未完成的任务"\n• "显示任务列表"';
    } else if (!isTaskQuery && !lowerText.contains('创建') && !lowerText.contains('添加') && !lowerText.contains('帮我') && !lowerText.contains('任务')) {
      // 非任务相关且没有明确创建意图的消息，回复不知道
      response = '抱歉，我不太明白你的意思 😅\n\n我可以帮你：\n• 创建任务："下周三完成报告"\n• 查询状态："我有多少未完成的任务"\n• 查看列表："显示所有任务"';
    } else {
      // 尝试创建任务
      final preferRemote = context.read<AiModeProvider>().preferRemote;
      final parsed = await AiDispatcherService().parseTask(
        text,
        preferRemote: preferRemote,
      );

      if (parsed.title.isEmpty) {
        response = '抱歉，我没能理解你的意思 😅\n\n你可以：\n• 直接输入任务描述创建任务，如"下周三完成报告"\n• 输入"显示任务"查看现有任务';
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
        _messages.add(ChatMessage(
          content: response,
          isUser: false,
          timestamp: aiNow,
          createdTask: createdTask,
        ));
        _isProcessing = false;
      });
    }

    // 保存AI回复
    await ChatStorageService.addMessage(StoredChatMessage(
      id: aiNow.millisecondsSinceEpoch.toString(),
      content: response,
      isUser: false,
      timestamp: aiNow,
    ));

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

  static const String _welcomeMessage = '你好！我是AiTODO助手，可以用自然语言帮我创建任务哦～\n\n比如：\n• "下周三完成项目报告"\n• "帮我创建一个紧急的工作任务"\n• "明天有个会议"\n\n也可以查询任务状态，比如：\n• "我有多少未完成的任务"\n• "显示今天要完成的任务"';

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        content: _welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    ChatStorageService.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 24),
            SizedBox(width: 8),
            Text('AI助手'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '清空聊天',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('清空聊天'),
                  content: const Text('确定要清空所有聊天记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _clearChat();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                // Input area
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            decoration: InputDecoration(
                              hintText: '输入任务描述...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _isProcessing ? null : _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: message.isUser ? const Radius.circular(4) : null,
                      bottomLeft: !message.isUser ? const Radius.circular(4) : null,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
