import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/providers/pomodoro_provider.dart';
import 'package:ai_todo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotificationService implements NotificationService {
  final scheduledPhases = <String>[];
  final foregroundPhases = <String>[];
  int cancelPomodoroCount = 0;
  int stopForegroundCount = 0;
  DateTime? lastScheduledEndAt;
  DateTime? lastForegroundEndAt;
  int? lastForegroundRemainingSeconds;

  @override
  Future<void> cancelAllReminders() async {}

  @override
  Future<void> cancelDailySummary() async {}

  @override
  Future<void> cancelPomodoroNotifications() async {
    cancelPomodoroCount++;
  }

  @override
  Future<void> cancelReminder(String taskId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<void> scheduleDailySummary(
    TimeOfDay time,
    int pendingCount, {
    List<String>? taskTitles,
  }) async {}

  @override
  Future<void> schedulePomodoroCompletion({
    required String phaseLabel,
    required DateTime endAt,
    required bool exactPreferred,
  }) async {
    scheduledPhases.add(phaseLabel);
    lastScheduledEndAt = endAt;
  }

  @override
  Future<void> scheduleTaskReminder(Task task) async {}

  @override
  Future<void> startPomodoroForegroundService({
    required String phaseLabel,
    required DateTime endAt,
    required int remainingSeconds,
  }) async {
    foregroundPhases.add(phaseLabel);
    lastForegroundEndAt = endAt;
    lastForegroundRemainingSeconds = remainingSeconds;
  }

  @override
  Future<void> stopPomodoroForegroundService() async {
    stopForegroundCount++;
  }

  @override
  Future<void> updateDailySummary(
    int pendingCount, {
    List<String>? taskTitles,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PomodoroProvider', () {
    late PomodoroProvider provider;
    late _FakeNotificationService notificationService;
    late DateTime now;

    PomodoroProvider createProvider() => PomodoroProvider(
      notificationService: notificationService,
      now: () => now,
      registerLifecycleObserver: false,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notificationService = _FakeNotificationService();
      now = DateTime(2026, 6, 16, 9);
      provider = createProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state should be idle with default values', () {
      expect(provider.state, PomodoroState.idle);
      expect(provider.remainingSeconds, 25 * 60);
      expect(provider.completedPomodoros, 0);
      expect(provider.currentTaskId, isNull);
      expect(provider.startedAt, isNull);
      expect(provider.endAt, isNull);
      expect(provider.pausedRemainingSeconds, isNull);
      expect(provider.isRunning, isFalse);
      expect(provider.isPaused, isFalse);
      expect(provider.timeDisplay, '25:00');
      expect(provider.progress, 0.0);
    });

    test('startWork should persist endAt and start notifications', () async {
      provider.workDuration = 60;

      await provider.startWork(taskId: 'task-123');

      expect(provider.state, PomodoroState.working);
      expect(provider.currentTaskId, 'task-123');
      expect(provider.startedAt, now);
      expect(provider.endAt, now.add(const Duration(seconds: 60)));
      expect(provider.remainingSeconds, 60);
      expect(provider.isRunning, isTrue);
      expect(provider.isPaused, isFalse);
      expect(notificationService.scheduledPhases, ['工作']);
      expect(notificationService.foregroundPhases, ['工作']);
      expect(notificationService.lastScheduledEndAt, provider.endAt);
      expect(notificationService.lastForegroundRemainingSeconds, 60);

      final restored = createProvider()..workDuration = 60;
      addTearDown(restored.dispose);
      now = now.add(const Duration(seconds: 10));
      await restored.initialize();

      expect(restored.state, PomodoroState.working);
      expect(restored.isRunning, isTrue);
      expect(restored.remainingSeconds, 50);
      expect(restored.endAt, provider.endAt);
    });

    test(
      'pause should save paused remaining and cancel pomodoro background work',
      () async {
        provider.workDuration = 60;
        await provider.startWork();

        now = now.add(const Duration(seconds: 12));
        await provider.pause();

        expect(provider.state, PomodoroState.working);
        expect(provider.isRunning, isFalse);
        expect(provider.isPaused, isTrue);
        expect(provider.remainingSeconds, 48);
        expect(provider.pausedRemainingSeconds, 48);
        expect(provider.endAt, isNull);
        expect(notificationService.cancelPomodoroCount, 1);
        expect(notificationService.stopForegroundCount, 1);

        final restored = createProvider()..workDuration = 60;
        addTearDown(restored.dispose);
        now = now.add(const Duration(minutes: 5));
        await restored.initialize();

        expect(restored.state, PomodoroState.working);
        expect(restored.isPaused, isTrue);
        expect(restored.remainingSeconds, 48);
      },
    );

    test('resume should create a fresh endAt from paused remaining', () async {
      provider.workDuration = 60;
      await provider.startWork();
      now = now.add(const Duration(seconds: 15));
      await provider.pause();

      now = now.add(const Duration(minutes: 5));
      await provider.resume();

      expect(provider.isRunning, isTrue);
      expect(provider.isPaused, isFalse);
      expect(provider.startedAt, now);
      expect(provider.endAt, now.add(const Duration(seconds: 45)));
      expect(provider.remainingSeconds, 45);
      expect(notificationService.scheduledPhases.last, '工作');
      expect(notificationService.foregroundPhases.last, '工作');
    });

    test('initialize should restore a running session from endAt', () async {
      provider.workDuration = 60;
      await provider.startWork(taskId: 'task-123');

      final restored = createProvider()..workDuration = 60;
      addTearDown(restored.dispose);
      now = now.add(const Duration(seconds: 25));
      await restored.initialize();

      expect(restored.state, PomodoroState.working);
      expect(restored.currentTaskId, 'task-123');
      expect(restored.isRunning, isTrue);
      expect(restored.remainingSeconds, 35);
      expect(restored.endAt, DateTime(2026, 6, 16, 9, 1));
    });

    test(
      'initialize should complete expired work once and start a break',
      () async {
        provider.workDuration = 60;
        provider.shortBreakDuration = 30;
        await provider.startWork();

        final restored = createProvider()
          ..workDuration = 60
          ..shortBreakDuration = 30;
        addTearDown(restored.dispose);
        now = now.add(const Duration(seconds: 70));
        await restored.initialize();

        expect(restored.completedPomodoros, 1);
        expect(restored.state, PomodoroState.shortBreak);
        expect(restored.isRunning, isTrue);
        expect(restored.remainingSeconds, 30);
        expect(restored.startedAt, now);
        expect(restored.endAt, now.add(const Duration(seconds: 30)));
        expect(notificationService.scheduledPhases.last, '短休息');
      },
    );

    test(
      'initialize should return to idle when a restored break has expired',
      () async {
        provider.shortBreakDuration = 30;
        await provider.startShortBreak();

        final restored = createProvider()..shortBreakDuration = 30;
        addTearDown(restored.dispose);
        now = now.add(const Duration(seconds: 35));
        await restored.initialize();

        expect(restored.state, PomodoroState.idle);
        expect(restored.isRunning, isFalse);
        expect(restored.remainingSeconds, restored.workDuration);
        expect(
          notificationService.stopForegroundCount,
          greaterThanOrEqualTo(1),
        );
      },
    );

    test('reset should clear the persisted session', () async {
      await provider.startWork(taskId: 'task-123');
      await provider.reset();

      expect(provider.state, PomodoroState.idle);
      expect(provider.remainingSeconds, provider.workDuration);
      expect(provider.currentTaskId, isNull);
      expect(provider.startedAt, isNull);
      expect(provider.endAt, isNull);
      expect(provider.pausedRemainingSeconds, isNull);
      expect(provider.isRunning, isFalse);
      expect(provider.isPaused, isFalse);

      final restored = createProvider();
      addTearDown(restored.dispose);
      await restored.initialize();

      expect(restored.state, PomodoroState.idle);
      expect(restored.currentTaskId, isNull);
    });

    test('skip should call _onTimerComplete', () async {
      await provider.startWork();
      await provider.skip();

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

    test('progress should calculate correctly', () async {
      await provider.startWork();
      final totalSeconds = provider.workDuration;

      expect(provider.progress, closeTo(0.0, 0.01));

      now = now.add(Duration(seconds: totalSeconds ~/ 2));
      expect(provider.progress, closeTo(0.5, 0.01));
    });

    test('completedPomodoros should increment on work completion', () async {
      for (int i = 0; i < 3; i++) {
        await provider.startWork();
        await provider.skip();
      }

      expect(provider.completedPomodoros, 3);
    });

    test('long break should occur after every 4 pomodoros', () async {
      for (int i = 0; i < 4; i++) {
        await provider.startWork();
        await provider.skip();
      }

      expect(provider.completedPomodoros, 4);
      expect(provider.state, PomodoroState.longBreak);
    });

    test('short break should occur after 1-3 pomodoros', () async {
      for (int i = 0; i < 2; i++) {
        await provider.startWork();
        await provider.skip();
      }

      expect(provider.completedPomodoros, 2);
      expect(provider.state, PomodoroState.shortBreak);
    });

    test('custom durations should affect timer', () async {
      provider.workDuration = 30 * 60;
      provider.shortBreakDuration = 3 * 60;
      provider.longBreakDuration = 10 * 60;

      await provider.startWork();
      expect(provider.remainingSeconds, 30 * 60);

      await provider.startShortBreak();
      expect(provider.remainingSeconds, 3 * 60);

      await provider.startLongBreak();
      expect(provider.remainingSeconds, 10 * 60);
    });
  });
}
