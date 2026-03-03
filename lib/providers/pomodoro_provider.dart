import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PomodoroState { idle, working, shortBreak, longBreak }

/// 番茄钟记录
class PomodoroRecord {
  final DateTime timestamp;
  final String? taskId;
  final int duration; // 秒

  PomodoroRecord({
    required this.timestamp,
    this.taskId,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'taskId': taskId,
    'duration': duration,
  };

  factory PomodoroRecord.fromJson(Map<String, dynamic> json) => PomodoroRecord(
    timestamp: DateTime.parse(json['timestamp'] as String),
    taskId: json['taskId'] as String?,
    duration: json['duration'] as int,
  );
}

class PomodoroProvider extends ChangeNotifier {
  static const String _historyKey = 'pomodoro_history';

  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;
  int _completedPomodoros = 0;
  String? _currentTaskId;
  List<PomodoroRecord> _history = []; // 番茄钟历史记录

  // 设置
  int workDuration = 25 * 60; // 25分钟
  int shortBreakDuration = 5 * 60; // 5分钟
  int longBreakDuration = 15 * 60; // 15分钟
  int pomodorosUntilLongBreak = 4;

  int remainingSeconds = 25 * 60;
  PomodoroState get state => _state;
  int get completedPomodoros => _completedPomodoros;
  String? get currentTaskId => _currentTaskId;

  String get timeDisplay {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = _getTotalSeconds();
    return 1 - (remainingSeconds / total);
  }

  int _getTotalSeconds() {
    switch (_state) {
      case PomodoroState.working:
        return workDuration;
      case PomodoroState.shortBreak:
        return shortBreakDuration;
      case PomodoroState.longBreak:
        return longBreakDuration;
      case PomodoroState.idle:
        return workDuration;
    }
  }

  void startWork({String? taskId}) {
    _currentTaskId = taskId;
    _state = PomodoroState.working;
    remainingSeconds = workDuration;
    _startTimer();
    notifyListeners();
  }

  void startShortBreak() {
    _state = PomodoroState.shortBreak;
    remainingSeconds = shortBreakDuration;
    _startTimer();
    notifyListeners();
  }

  void startLongBreak() {
    _state = PomodoroState.longBreak;
    remainingSeconds = longBreakDuration;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    notifyListeners();
  }

  void resume() {
    _startTimer();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    remainingSeconds = workDuration;
    _currentTaskId = null;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _onTimerComplete();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    if (_state == PomodoroState.working) {
      _completedPomodoros++;
      // 添加番茄钟记录
      _addRecord(taskId: _currentTaskId, duration: workDuration);
    }
    notifyListeners();

    // 自动切换状态
    if (_state == PomodoroState.working) {
      if (_completedPomodoros % pomodorosUntilLongBreak == 0) {
        startLongBreak();
      } else {
        startShortBreak();
      }
    } else {
      // 休息结束后回到空闲
      _state = PomodoroState.idle;
      remainingSeconds = workDuration;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============= 番茄钟统计 =============

  /// 获取今日番茄钟数量
  int get todayPomodoros {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history
        .where((r) => r.timestamp.isAfter(today))
        .length;
  }

  /// 获取本周番茄钟数量
  int get weekPomodoros {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _history
        .where((r) => r.timestamp.isAfter(startOfWeek))
        .length;
  }

  /// 获取本月番茄钟数量
  int get monthPomodoros {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _history
        .where((r) => r.timestamp.isAfter(startOfMonth))
        .length;
  }

  /// 获取总番茄钟数量
  int get totalPomodoros => _history.length;

  /// 获取今日专注分钟数
  int get todayFocusMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history
        .where((r) => r.timestamp.isAfter(today))
        .fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 获取本周专注分钟数
  int get weekFocusMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _history
        .where((r) => r.timestamp.isAfter(startOfWeek))
        .fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 获取本月专注分钟数
  int get monthFocusMinutes {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _history
        .where((r) => r.timestamp.isAfter(startOfMonth))
        .fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 获取总专注分钟数
  int get totalFocusMinutes {
    return _history.fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 获取指定日期范围的番茄钟数量
  int getPomodorosInRange(DateTime start, DateTime end) {
    return _history
        .where((r) =>
            r.timestamp.isAfter(start) && r.timestamp.isBefore(end))
        .length;
  }

  /// 获取每日番茄钟统计（过去N天）
  Map<DateTime, int> getDailyStats(int days) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final nextDate = date.add(const Duration(days: 1));
      result[date] = _history
          .where((r) =>
              r.timestamp.isAfter(date) && r.timestamp.isBefore(nextDate))
          .length;
    }

    return result;
  }

  /// 获取任务专注时间（分钟）
  int getFocusTimeForTask(String taskId) {
    return _history
        .where((r) => r.taskId == taskId)
        .fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history = decoded
            .map((e) => PomodoroRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // 忽略加载错误
    }
  }

  /// 保存历史记录
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      // 忽略保存错误
    }
  }

  /// 添加番茄钟记录
  void _addRecord({String? taskId, required int duration}) {
    _history.add(PomodoroRecord(
      timestamp: DateTime.now(),
      taskId: taskId,
      duration: duration,
    ));
    _saveHistory();
  }

  /// 清除历史记录
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }
}
