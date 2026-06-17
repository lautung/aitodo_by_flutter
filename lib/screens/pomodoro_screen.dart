import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';
import '../widgets/ui/ui.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, child) {
        return AppPageScaffold(
          title: '番茄钟',
          subtitle: _subtitleForState(provider.state),
          leadingIcon: Icons.timer_outlined,
          scrollable: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight < 560;
              final timerSize = isCompactHeight ? 210.0 : 250.0;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      AppSurface(
                        padding: EdgeInsets.all(isCompactHeight ? 18 : 24),
                        child: Column(
                          children: [
                            _StatePill(provider: provider),
                            SizedBox(height: isCompactHeight ? 18 : 28),
                            _TimerDial(provider: provider, size: timerSize),
                            SizedBox(height: isCompactHeight ? 18 : 28),
                            _PomodoroControls(provider: provider),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppMetricGrid(
                        children: [
                          AppMetricCard(
                            label: '今日完成',
                            value: '${provider.completedPomodoros}',
                            helper: '专注轮次',
                            icon: Icons.check_circle_outline,
                            color: Colors.teal,
                          ),
                          AppMetricCard(
                            label: '工作时长',
                            value: '${provider.completedPomodoros * 25} 分钟',
                            helper: '按标准番茄钟估算',
                            icon: Icons.schedule,
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _subtitleForState(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return '准备一次安静的专注';
      case PomodoroState.working:
        return '保持节奏，先完成眼前这一段';
      case PomodoroState.shortBreak:
        return '短休息，给大脑一点空间';
      case PomodoroState.longBreak:
        return '长休息，恢复后再继续';
    }
  }
}

class _StatePill extends StatelessWidget {
  final PomodoroProvider provider;

  const _StatePill({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(provider.state);
    return AppInfoPill(
      label: _stateLabel(provider.state),
      color: color,
      icon: provider.isRunning ? Icons.bolt : Icons.radio_button_checked,
      emphasized: true,
    );
  }

  static String _stateLabel(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return '准备开始';
      case PomodoroState.working:
        return '工作中';
      case PomodoroState.shortBreak:
        return '短休息';
      case PomodoroState.longBreak:
        return '长休息';
    }
  }

  static Color _stateColor(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return Colors.blueGrey;
      case PomodoroState.working:
        return Colors.red;
      case PomodoroState.shortBreak:
        return Colors.green;
      case PomodoroState.longBreak:
        return Colors.indigo;
    }
  }
}

class _TimerDial extends StatelessWidget {
  final PomodoroProvider provider;
  final double size;

  const _TimerDial({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _StatePill._stateColor(provider.state);
    final timeFontSize = size < 230 ? 40.0 : 48.0;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _TimerDialPainter(
          progress: provider.progress,
          color: color,
          trackColor: colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.timeDisplay,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: timeFontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '番茄数: ${provider.completedPomodoros}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PomodoroControls extends StatelessWidget {
  final PomodoroProvider provider;

  const _PomodoroControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final primaryAction = provider.state == PomodoroState.idle
        ? _ControlAction(
            label: '开始工作',
            icon: Icons.play_arrow,
            onPressed: () => unawaited(provider.startWork()),
          )
        : provider.isRunning
        ? _ControlAction(
            label: '暂停',
            icon: Icons.pause,
            onPressed: () => unawaited(provider.pause()),
          )
        : _ControlAction(
            label: '继续',
            icon: Icons.play_arrow,
            onPressed: () => unawaited(provider.resume()),
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: '重置',
          onPressed: () => unawaited(provider.reset()),
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: AppSpacing.md),
        FilledButton.icon(
          onPressed: primaryAction.onPressed,
          icon: Icon(primaryAction.icon),
          label: Text(primaryAction.label),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton.filledTonal(
          tooltip: '跳过',
          onPressed: () => unawaited(provider.skip()),
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}

class _ControlAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class _TimerDialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _TimerDialPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 14) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
