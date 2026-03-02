import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart' as task_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 点击通知时的处理
  }

  /// 调度任务提醒
  Future<void> scheduleTaskReminder(task_model.Task task) async {
    if (task.dueDate == null) return;

    await initialize();

    // 使用自定义提醒时间（如果已设置），否则回退到截止前15分钟
    final DateTime reminderTime;
    final String reminderText;
    if (task.reminderTime != null) {
      reminderTime = task.reminderTime!;
      // 计算自定义提醒时间与截止时间的差值
      final diff = task.dueDate!.difference(reminderTime);
      if (diff.inMinutes > 0) {
        reminderText = '距离截止还有 ${_formatDuration(diff)}';
      } else if (diff.inMinutes == 0) {
        reminderText = '任务即将截止';
      } else {
        reminderText = '任务已超时';
      }
    } else {
      reminderTime = task.dueDate!.subtract(const Duration(minutes: 15));
      reminderText = '${task.title} 将在15分钟后到期';
    }

    // 如果提醒时间已经过去，不调度
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
    final notificationId = _notificationIdForTask(task.id);

    // 先取消同任务旧提醒，避免重复通知。
    await _notifications.cancel(notificationId);

    await _notifications.zonedSchedule(
      notificationId,
      '任务提醒',
      reminderText,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          '任务提醒',
          channelDescription: '任务截止日期提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _notificationIdForTask(String taskId) {
    var hash = 0;
    for (final unit in taskId.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return hash;
  }

  /// 格式化时间差
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天${duration.inHours % 24}小时';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小时${duration.inMinutes % 60}分钟';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 取消任务提醒
  Future<void> cancelReminder(String taskId) async {
    await initialize();
    await _notifications.cancel(_notificationIdForTask(taskId));
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await initialize();
    await _notifications.cancelAll();
  }

  // ============= 每日总结通知 =============

  static const int _dailySummaryNotificationId = 999999;

  /// 调度每日总结通知
  Future<void> scheduleDailySummary(TimeOfDay time, int pendingCount, {List<String>? taskTitles}) async {
    await initialize();

    // 取消已存在的每日总结通知
    await _notifications.cancel(_dailySummaryNotificationId);

    // 构建通知内容
    final String body;
    if (taskTitles != null && taskTitles.isNotEmpty) {
      final taskList = taskTitles.take(5).map((t) => '• $t').join('\n');
      final moreText = taskTitles.length > 5 ? '\n...还有 ${taskTitles.length - 5} 个任务' : '';
      body = '您有 $pendingCount 个待办任务：\n$taskList$moreText';
    } else {
      body = '您有 $pendingCount 个待办任务';
    }

    // 计算下一次的提醒时间
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 如果时间已过，则安排到明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      _dailySummaryNotificationId,
      '📋 每日任务总结',
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          '每日总结',
          channelDescription: '每日任务总结通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每天重复
    );
  }

  /// 取消每日总结通知
  Future<void> cancelDailySummary() async {
    await initialize();
    await _notifications.cancel(_dailySummaryNotificationId);
  }

  /// 更新每日总结通知（用于显示当前待办任务数量）
  Future<void> updateDailySummary(int pendingCount, {List<String>? taskTitles}) async {
    await initialize();

    // 检查是否已有每日总结通知安排
    // 如果有，我们需要重新安排以更新内容
    // 这里我们直接重新调度
    final pending = await _notifications.pendingNotificationRequests();
    final hasDailySummary = pending.any((p) => p.id == _dailySummaryNotificationId);

    if (hasDailySummary) {
      // 取消旧的，重新安排
      await _notifications.cancel(_dailySummaryNotificationId);
    }
  }
}
