import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

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

class PomodoroProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const String _historyKey = 'pomodoro_history';
  static const String _sessionKey = 'pomodoro_session';

  PomodoroProvider({
    NotificationService? notificationService,
    DateTime Function()? now,
    bool registerLifecycleObserver = true,
  }) : _notificationService = notificationService ?? NotificationService(),
       _now = now ?? DateTime.now,
       _shouldRegisterLifecycleObserver = registerLifecycleObserver {
    if (_shouldRegisterLifecycleObserver) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _registeredLifecycleObserver = true;
      } catch (_) {
        _registeredLifecycleObserver = false;
      }
    }
  }

  final NotificationService _notificationService;
  final DateTime Function() _now;
  final bool _shouldRegisterLifecycleObserver;
  bool _registeredLifecycleObserver = false;

  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;
  bool _isRunning = false;
  int _completedPomodoros = 0;
  String? _currentTaskId;
  DateTime? _startedAt;
  DateTime? _endAt;
  int? _pausedRemainingSeconds;
  List<PomodoroRecord> _history = []; // 番茄钟历史记录

  // 设置
  int workDuration = 25 * 60; // 25分钟
  int shortBreakDuration = 5 * 60; // 5分钟
  int longBreakDuration = 15 * 60; // 15分钟
  int pomodorosUntilLongBreak = 4;

  int remainingSeconds = 25 * 60;
  PomodoroState get state => _state;
  bool get isRunning => _isRunning;
  bool get isPaused => _state != PomodoroState.idle && !_isRunning;
  int get completedPomodoros => _completedPomodoros;
  String? get currentTaskId => _currentTaskId;
  DateTime? get startedAt => _startedAt;
  DateTime? get endAt => _endAt;
  int? get pausedRemainingSeconds => _pausedRemainingSeconds;

  String get timeDisplay {
    final displaySeconds = _displayRemainingSeconds;
    final minutes = displaySeconds ~/ 60;
    final seconds = displaySeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final total = _getTotalSeconds();
    if (total <= 0) {
      return 0;
    }
    return 1 - (_displayRemainingSeconds / total);
  }

  int get _displayRemainingSeconds {
    if (_isRunning && _endAt != null) {
      return _secondsUntil(_endAt!);
    }
    return remainingSeconds;
  }

  Future<void> initialize() async {
    await loadHistory();
    await restoreSession();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson == null) {
      return;
    }

    try {
      final session = json.decode(sessionJson) as Map<String, dynamic>;
      _state = _stateFromName(session['state'] as String?);
      _isRunning = session['isRunning'] == true;
      _completedPomodoros = session['completedPomodoros'] as int? ?? 0;
      _currentTaskId = session['currentTaskId'] as String?;
      _startedAt = _parseDateTime(session['startedAt']);
      _endAt = _parseDateTime(session['endAt']);
      _pausedRemainingSeconds = session['pausedRemainingSeconds'] as int?;
      remainingSeconds =
          session['remainingSeconds'] as int? ?? _getTotalSeconds();

      if (_state == PomodoroState.idle) {
        await _clearSession();
        notifyListeners();
        return;
      }

      if (_isRunning && _endAt != null) {
        remainingSeconds = _secondsUntil(_endAt!);
        if (remainingSeconds <= 0) {
          await _handleTimerComplete();
          return;
        }

        _startTicker();
        await _saveSession();
        await _syncPomodoroBackgroundWork();
      } else {
        _isRunning = false;
        _timer?.cancel();
        _timer = null;
        _endAt = null;
        _startedAt = null;
        remainingSeconds =
            _pausedRemainingSeconds ??
            remainingSeconds.clamp(0, _getTotalSeconds());
        await _saveSession();
      }

      notifyListeners();
    } catch (error) {
      debugPrint('Failed to restore pomodoro session: $error');
      await _clearSession();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(restoreSession());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _refreshRemainingFromEndAt();
      unawaited(_saveSession());
    }
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

  Future<void> startWork({String? taskId}) {
    _currentTaskId = taskId;
    return _startPhase(PomodoroState.working, workDuration);
  }

  Future<void> startShortBreak() {
    return _startPhase(PomodoroState.shortBreak, shortBreakDuration);
  }

  Future<void> startLongBreak() {
    return _startPhase(PomodoroState.longBreak, longBreakDuration);
  }

  Future<void> pause() async {
    if (_state == PomodoroState.idle || !_isRunning) {
      return;
    }

    _refreshRemainingFromEndAt();
    if (remainingSeconds <= 0) {
      await _handleTimerComplete();
      return;
    }

    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _pausedRemainingSeconds = remainingSeconds;
    _startedAt = null;
    _endAt = null;
    await _cancelPomodoroBackgroundWork();
    await _saveSession();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state == PomodoroState.idle || _isRunning) {
      return;
    }

    final resumeSeconds = _pausedRemainingSeconds ?? remainingSeconds;
    if (resumeSeconds <= 0) {
      await _handleTimerComplete();
      return;
    }

    remainingSeconds = resumeSeconds;
    await _startPhase(_state, resumeSeconds);
  }

  Future<void> reset() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _state = PomodoroState.idle;
    remainingSeconds = workDuration;
    _currentTaskId = null;
    _startedAt = null;
    _endAt = null;
    _pausedRemainingSeconds = null;
    await _cancelPomodoroBackgroundWork();
    await _clearSession();
    notifyListeners();
  }

  Future<void> skip() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _startedAt = null;
    _endAt = null;
    _pausedRemainingSeconds = null;
    await _handleTimerComplete();
  }

  Future<void> _startPhase(PomodoroState nextState, int durationSeconds) async {
    final now = _now();
    _timer?.cancel();
    _state = nextState;
    _isRunning = true;
    _startedAt = now;
    _endAt = now.add(Duration(seconds: durationSeconds));
    _pausedRemainingSeconds = null;
    remainingSeconds = durationSeconds;
    _startTicker();
    await _saveSession();
    await _syncPomodoroBackgroundWork();
    notifyListeners();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) {
        return;
      }

      _refreshRemainingFromEndAt();
      if (remainingSeconds <= 0) {
        unawaited(_handleTimerComplete());
      } else {
        notifyListeners();
      }
    });
  }

  void _refreshRemainingFromEndAt() {
    if (_isRunning && _endAt != null) {
      remainingSeconds = _secondsUntil(_endAt!);
    }
  }

  int _secondsUntil(DateTime endAt) {
    return math.max(0, endAt.difference(_now()).inSeconds);
  }

  Future<void> _handleTimerComplete() async {
    if (_state == PomodoroState.idle) {
      return;
    }

    final completedState = _state;
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _startedAt = null;
    _endAt = null;
    _pausedRemainingSeconds = null;
    remainingSeconds = 0;
    await _cancelPomodoroBackgroundWork();

    if (completedState == PomodoroState.working) {
      _completedPomodoros++;
      _addRecord(taskId: _currentTaskId, duration: workDuration);

      if (_completedPomodoros % pomodorosUntilLongBreak == 0) {
        await startLongBreak();
      } else {
        await startShortBreak();
      }
    } else {
      _state = PomodoroState.idle;
      remainingSeconds = workDuration;
      await _clearSession();
      notifyListeners();
    }
  }

  Future<void> _syncPomodoroBackgroundWork() async {
    if (!_isRunning || _endAt == null || _state == PomodoroState.idle) {
      return;
    }

    final phaseLabel = _labelForState(_state);
    try {
      await _notificationService.schedulePomodoroCompletion(
        phaseLabel: phaseLabel,
        endAt: _endAt!,
        exactPreferred: true,
      );
    } catch (error) {
      debugPrint('Failed to schedule pomodoro completion notification: $error');
    }

    try {
      await _notificationService.startPomodoroForegroundService(
        phaseLabel: phaseLabel,
        endAt: _endAt!,
        remainingSeconds: _displayRemainingSeconds,
      );
    } catch (error) {
      debugPrint('Failed to start pomodoro foreground service: $error');
    }
  }

  Future<void> _cancelPomodoroBackgroundWork() async {
    try {
      await _notificationService.cancelPomodoroNotifications();
    } catch (error) {
      debugPrint('Failed to cancel pomodoro notification: $error');
    }

    try {
      await _notificationService.stopPomodoroForegroundService();
    } catch (error) {
      debugPrint('Failed to stop pomodoro foreground service: $error');
    }
  }

  String _labelForState(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return '准备开始';
      case PomodoroState.working:
        return '工作';
      case PomodoroState.shortBreak:
        return '短休息';
      case PomodoroState.longBreak:
        return '长休息';
    }
  }

  PomodoroState _stateFromName(String? name) {
    return PomodoroState.values.firstWhere(
      (state) => state.name == name,
      orElse: () => PomodoroState.idle,
    );
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is! String) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> _saveSession() async {
    if (_state == PomodoroState.idle && !_isRunning) {
      await _clearSession();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      json.encode({
        'state': _state.name,
        'isRunning': _isRunning,
        'completedPomodoros': _completedPomodoros,
        'currentTaskId': _currentTaskId,
        'startedAt': _startedAt?.toIso8601String(),
        'endAt': _endAt?.toIso8601String(),
        'pausedRemainingSeconds': _pausedRemainingSeconds,
        'remainingSeconds': _displayRemainingSeconds,
      }),
    );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    if (_registeredLifecycleObserver) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  // ============= 番茄钟统计 =============

  /// 获取今日番茄钟数量
  int get todayPomodoros {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history.where((r) => r.timestamp.isAfter(today)).length;
  }

  /// 获取本周番茄钟数量
  int get weekPomodoros {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    return _history.where((r) => r.timestamp.isAfter(startOfWeek)).length;
  }

  /// 获取本月番茄钟数量
  int get monthPomodoros {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _history.where((r) => r.timestamp.isAfter(startOfMonth)).length;
  }

  /// 获取总番茄钟数量
  int get totalPomodoros => _history.length;

  /// 获取今日专注分钟数
  int get todayFocusMinutes {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _history
            .where((r) => r.timestamp.isAfter(today))
            .fold(0, (sum, r) => sum + r.duration) ~/
        60;
  }

  /// 获取本周专注分钟数
  int get weekFocusMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    return _history
            .where((r) => r.timestamp.isAfter(startOfWeek))
            .fold(0, (sum, r) => sum + r.duration) ~/
        60;
  }

  /// 获取本月专注分钟数
  int get monthFocusMinutes {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _history
            .where((r) => r.timestamp.isAfter(startOfMonth))
            .fold(0, (sum, r) => sum + r.duration) ~/
        60;
  }

  /// 获取总专注分钟数
  int get totalFocusMinutes {
    return _history.fold(0, (sum, r) => sum + r.duration) ~/ 60;
  }

  /// 获取指定日期范围的番茄钟数量
  int getPomodorosInRange(DateTime start, DateTime end) {
    return _history
        .where((r) => r.timestamp.isAfter(start) && r.timestamp.isBefore(end))
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
          .where(
            (r) => r.timestamp.isAfter(date) && r.timestamp.isBefore(nextDate),
          )
          .length;
    }

    return result;
  }

  /// 获取任务专注时间（分钟）
  int getFocusTimeForTask(String taskId) {
    return _history
            .where((r) => r.taskId == taskId)
            .fold(0, (sum, r) => sum + r.duration) ~/
        60;
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
    _history.add(
      PomodoroRecord(timestamp: _now(), taskId: taskId, duration: duration),
    );
    unawaited(_saveHistory());
  }

  /// 清除历史记录
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _state = PomodoroState.idle;
    _completedPomodoros = 0;
    _currentTaskId = null;
    _startedAt = null;
    _endAt = null;
    _pausedRemainingSeconds = null;
    _history.clear();
    remainingSeconds = workDuration;
    await _cancelPomodoroBackgroundWork();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_sessionKey);
    notifyListeners();
  }
}
