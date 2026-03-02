import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 存储用的聊天消息模型
class StoredChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  StoredChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory StoredChatMessage.fromJson(Map<String, dynamic> json) {
    return StoredChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ChatStorageService {
  static const String _chatMessagesKey = 'chat_messages';
  static const int _maxMessages = 100;

  /// 加载聊天消息
  static Future<List<StoredChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_chatMessagesKey);

    if (messagesJson == null || messagesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> messagesList = json.decode(messagesJson);
      return messagesList
          .map((json) => StoredChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存聊天消息
  static Future<void> saveMessages(List<StoredChatMessage> messages) async {
    final limitedMessages = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;

    final prefs = await SharedPreferences.getInstance();
    final messagesJson = json.encode(
      limitedMessages.map((m) => m.toJson()).toList(),
    );
    await prefs.setString(_chatMessagesKey, messagesJson);
  }

  /// 添加单条消息
  static Future<void> addMessage(StoredChatMessage message) async {
    final messages = await loadMessages();
    messages.add(message);
    await saveMessages(messages);
  }

  /// 清空聊天记录
  static Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatMessagesKey);
  }
}
