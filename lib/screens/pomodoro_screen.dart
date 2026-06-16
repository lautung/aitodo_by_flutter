import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, provider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isCompactHeight = constraints.maxHeight < 640;
                final isVeryCompactHeight = constraints.maxHeight < 500;
                final timerSize = isVeryCompactHeight
                    ? 200.0
                    : isCompactHeight
                    ? 220.0
                    : 250.0;
                final sectionGap = isVeryCompactHeight
                    ? 18.0
                    : isCompactHeight
                    ? 24.0
                    : 40.0;
                final verticalPadding = isCompactHeight ? 16.0 : 24.0;
                final minContentHeight =
                    constraints.maxHeight - (verticalPadding * 2);

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    32,
                    verticalPadding,
                    32,
                    verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: minContentHeight > 0 ? minContentHeight : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 状态显示
                        _buildStateIndicator(provider),
                        SizedBox(height: sectionGap),

                        // 计时器
                        _buildTimer(context, provider, timerSize),
                        SizedBox(height: sectionGap),

                        // 控制按钮
                        _buildControls(context, provider),
                        SizedBox(height: sectionGap),

                        // 统计
                        _buildStats(provider),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStateIndicator(PomodoroProvider provider) {
    String stateText;
    Color stateColor;

    switch (provider.state) {
      case PomodoroState.idle:
        stateText = '准备开始';
        stateColor = Colors.grey;
        break;
      case PomodoroState.working:
        stateText = '工作中';
        stateColor = Colors.red;
        break;
      case PomodoroState.shortBreak:
        stateText = '短休息';
        stateColor = Colors.green;
        break;
      case PomodoroState.longBreak:
        stateText = '长休息';
        stateColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        stateText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: stateColor,
        ),
      ),
    );
  }

  Widget _buildTimer(
    BuildContext context,
    PomodoroProvider provider,
    double size,
  ) {
    final timeFontSize = size < 220 ? 40.0 : 48.0;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度圆环
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: provider.progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForState(provider.state),
              ),
            ),
          ),
          // 时间显示
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.timeDisplay,
                style: TextStyle(
                  fontSize: timeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '番茄数: ${provider.completedPomodoros}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForState(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return Colors.grey;
      case PomodoroState.working:
        return Colors.red;
      case PomodoroState.shortBreak:
        return Colors.green;
      case PomodoroState.longBreak:
        return Colors.blue;
    }
  }

  Widget _buildControls(BuildContext context, PomodoroProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 重置按钮
        IconButton.filled(
          onPressed: () => unawaited(provider.reset()),
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 20),

        // 主按钮
        if (provider.state == PomodoroState.idle)
          ElevatedButton.icon(
            onPressed: () => unawaited(provider.startWork()),
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始工作'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else if (provider.isRunning)
          ElevatedButton.icon(
            onPressed: () => unawaited(provider.pause()),
            icon: const Icon(Icons.pause),
            label: const Text('暂停'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () => unawaited(provider.resume()),
            icon: const Icon(Icons.play_arrow),
            label: const Text('继续'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

        const SizedBox(width: 20),

        // 跳过按钮
        IconButton.filled(
          onPressed: () => unawaited(provider.skip()),
          icon: const Icon(Icons.skip_next),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(PomodoroProvider provider) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildStatItem(
                '今日完成',
                '${provider.completedPomodoros}',
                Icons.check_circle,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                '工作时长',
                '${provider.completedPomodoros * 25}分钟',
                Icons.timer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
