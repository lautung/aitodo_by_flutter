import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart' as task_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int pomodoroForegroundNotificationId = 900001;
  static const int pomodoroCompletionNotificationId = 900002;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.requestNotificationsPermission() ?? true;
    }

    if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }

    if (Platform.isMacOS) {
      final macPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      return await macPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }

    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // 点击通知时的处理
  }

  /// 调度任务提醒
  Future<void> scheduleTaskReminder(task_model.Task task) async {
    if (task.dueDate == null) return;

    await initialize();

    final DateTime reminderTime;
    final String reminderText;
    if (task.reminderTime != null) {
      reminderTime = task.reminderTime!;
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

    if (reminderTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);
    final notificationId = _notificationIdForTask(task.id);

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
        iOS: DarwinNotificationDetails(threadIdentifier: 'task_reminders'),
        macOS: DarwinNotificationDetails(threadIdentifier: 'task_reminders'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> schedulePomodoroCompletion({
    required String phaseLabel,
    required DateTime endAt,
    required bool exactPreferred,
  }) async {
    if (endAt.isBefore(DateTime.now())) {
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    await initialize();
    await _notifications.cancel(pomodoroCompletionNotificationId);

    final scheduleMode = await _resolvePomodoroScheduleMode(exactPreferred);
    try {
      await _schedulePomodoroCompletionWithMode(
        phaseLabel: phaseLabel,
        endAt: endAt,
        scheduleMode: scheduleMode,
      );
    } on PlatformException {
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle ||
          scheduleMode == AndroidScheduleMode.exact ||
          scheduleMode == AndroidScheduleMode.alarmClock) {
        await _schedulePomodoroCompletionWithMode(
          phaseLabel: phaseLabel,
          endAt: endAt,
          scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> _schedulePomodoroCompletionWithMode({
    required String phaseLabel,
    required DateTime endAt,
    required AndroidScheduleMode scheduleMode,
  }) async {
    final tzTime = tz.TZDateTime.from(endAt, tz.local);
    await _notifications.zonedSchedule(
      pomodoroCompletionNotificationId,
      '$phaseLabel结束',
      phaseLabel == '工作' ? '该休息一下了' : '休息结束，准备开始下一轮',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_complete',
          '番茄钟结束提醒',
          channelDescription: '番茄钟阶段结束时提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'pomodoro'),
        macOS: DarwinNotificationDetails(threadIdentifier: 'pomodoro'),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pomodoro_complete',
    );
  }

  Future<AndroidScheduleMode> _resolvePomodoroScheduleMode(
    bool exactPreferred,
  ) async {
    if (!Platform.isAndroid || !exactPreferred) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    try {
      var canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        canScheduleExact =
            await androidPlugin.requestExactAlarmsPermission() ?? false;
      }

      return canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } on PlatformException {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> startPomodoroForegroundService({
    required String phaseLabel,
    required DateTime endAt,
    required int remainingSeconds,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }

    await initialize();
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.startForegroundService(
      pomodoroForegroundNotificationId,
      '番茄钟正在运行',
      '$phaseLabel · 剩余 ${_formatDuration(Duration(seconds: remainingSeconds))}',
      notificationDetails: AndroidNotificationDetails(
        'pomodoro_foreground',
        '番茄钟运行中',
        channelDescription: '番茄钟后台运行常驻通知',
        importance: Importance.low,
        priority: Priority.low,
        icon: '@mipmap/ic_launcher',
        ongoing: true,
        autoCancel: false,
        silent: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: endAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
      ),
      payload: 'pomodoro_foreground',
      foregroundServiceTypes: const {
        AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
      },
    );
  }

  Future<void> stopPomodoroForegroundService() async {
    if (!Platform.isAndroid) {
      return;
    }

    await initialize();
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.stopForegroundService();
    await _notifications.cancel(pomodoroForegroundNotificationId);
  }

  Future<void> cancelPomodoroNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    await initialize();
    await _notifications.cancel(pomodoroCompletionNotificationId);
    await _notifications.cancel(pomodoroForegroundNotificationId);
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
  Future<void> scheduleDailySummary(
    TimeOfDay time,
    int pendingCount, {
    List<String>? taskTitles,
  }) async {
    await initialize();

    await _notifications.cancel(_dailySummaryNotificationId);

    final String body;
    if (taskTitles != null && taskTitles.isNotEmpty) {
      final taskList = taskTitles.take(5).map((t) => '- $t').join('\n');
      final moreText = taskTitles.length > 5
          ? '\n...还有 ${taskTitles.length - 5} 个任务'
          : '';
      body = '您有 $pendingCount 个待办任务：\n$taskList$moreText';
    } else {
      body = '您有 $pendingCount 个待办任务';
    }

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      _dailySummaryNotificationId,
      '每日任务总结',
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
        iOS: DarwinNotificationDetails(threadIdentifier: 'daily_summary'),
        macOS: DarwinNotificationDetails(threadIdentifier: 'daily_summary'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消每日总结通知
  Future<void> cancelDailySummary() async {
    await initialize();
    await _notifications.cancel(_dailySummaryNotificationId);
  }

  /// 更新每日总结通知（用于显示当前待办任务数量）
  Future<void> updateDailySummary(
    int pendingCount, {
    List<String>? taskTitles,
  }) async {
    await initialize();

    final pending = await _notifications.pendingNotificationRequests();
    final hasDailySummary = pending.any(
      (p) => p.id == _dailySummaryNotificationId,
    );

    if (hasDailySummary) {
      await _notifications.cancel(_dailySummaryNotificationId);
    }
  }
}
