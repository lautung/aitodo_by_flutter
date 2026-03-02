import 'dart:async';
import 'package:flutter/foundation.dart';

enum PomodoroState { idle, working, shortBreak, longBreak }

class PomodoroProvider extends ChangeNotifier {
  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;
  int _completedPomodoros = 0;
  String? _currentTaskId;

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
}
