import 'package:ai_todo/providers/pomodoro_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PomodoroProvider', () {
    late PomodoroProvider provider;

    setUp(() {
      provider = PomodoroProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state should be idle with default values', () {
      expect(provider.state, PomodoroState.idle);
      expect(provider.remainingSeconds, 25 * 60);
      expect(provider.completedPomodoros, 0);
      expect(provider.currentTaskId, isNull);
      expect(provider.timeDisplay, '25:00');
      expect(provider.progress, 0.0);
    });

    test('startWork should set state to working with taskId', () {
      provider.startWork(taskId: 'task-123');

      expect(provider.state, PomodoroState.working);
      expect(provider.currentTaskId, 'task-123');
      expect(provider.remainingSeconds, provider.workDuration);
    });

    test('startShortBreak should set state to shortBreak', () {
      provider.startWork();
      provider.startShortBreak();

      expect(provider.state, PomodoroState.shortBreak);
      expect(provider.remainingSeconds, provider.shortBreakDuration);
    });

    test('startLongBreak should set state to longBreak', () {
      provider.startWork();
      provider.startLongBreak();

      expect(provider.state, PomodoroState.longBreak);
      expect(provider.remainingSeconds, provider.longBreakDuration);
    });

    test('pause should stop timer but keep state', () {
      provider.startWork();
      provider.pause();

      // Timer is internal, but state should remain working
      expect(provider.state, PomodoroState.working);
    });

    test('resume should restart timer', () {
      provider.startWork();
      provider.pause();
      provider.resume();

      expect(provider.state, PomodoroState.working);
    });

    test('reset should return to idle state', () {
      provider.startWork(taskId: 'task-123');
      provider.reset();

      expect(provider.state, PomodoroState.idle);
      expect(provider.remainingSeconds, provider.workDuration);
      expect(provider.currentTaskId, isNull);
    });

    test('skip should call _onTimerComplete', () {
      // Start with some completed pomodoros
      provider.startWork();
      provider.skip();

      // After completing a work session, should be in break state
      expect(provider.completedPomodoros, 1);
      expect(
        provider.state,
        anyOf(PomodoroState.shortBreak, PomodoroState.longBreak),
      );
    });

    test('timeDisplay should format correctly', () {
      provider.remainingSeconds = 125; // 2:05
      expect(provider.timeDisplay, '02:05');

      provider.remainingSeconds = 65; // 1:05
      expect(provider.timeDisplay, '01:05');

      provider.remainingSeconds = 5; // 0:05
      expect(provider.timeDisplay, '00:05');
    });

    test('progress should calculate correctly', () {
      provider.startWork();
      final totalSeconds = provider.workDuration;

      // At start, progress should be 0
      expect(provider.progress, closeTo(0.0, 0.01));

      // We can't easily test progress in the middle without mocking time,
      // but we can verify the calculation logic
      provider.remainingSeconds = totalSeconds ~/ 2;
      expect(provider.progress, closeTo(0.5, 0.01));
    });

    test('completedPomodoros should increment on work completion', () {
      // Simulate completing 3 work sessions
      for (int i = 0; i < 3; i++) {
        provider.startWork();
        provider.skip();
      }

      expect(provider.completedPomodoros, 3);
    });

    test('long break should occur after every 4 pomodoros', () {
      // Complete 4 pomodoros
      for (int i = 0; i < 4; i++) {
        provider.startWork();
        provider.skip();
      }

      // After 4th pomodoro, should be in long break
      expect(provider.completedPomodoros, 4);
      expect(provider.state, PomodoroState.longBreak);
    });

    test('short break should occur after 1-3 pomodoros', () {
      // Complete 2 pomodoros
      for (int i = 0; i < 2; i++) {
        provider.startWork();
        provider.skip();
      }

      expect(provider.completedPomodoros, 2);
      expect(provider.state, PomodoroState.shortBreak);
    });

    test('custom durations should affect timer', () {
      provider.workDuration = 30 * 60;
      provider.shortBreakDuration = 3 * 60;
      provider.longBreakDuration = 10 * 60;

      provider.startWork();
      expect(provider.remainingSeconds, 30 * 60);

      provider.startShortBreak();
      expect(provider.remainingSeconds, 3 * 60);

      provider.startLongBreak();
      expect(provider.remainingSeconds, 10 * 60);
    });
  });
}
