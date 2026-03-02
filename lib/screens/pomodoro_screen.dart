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
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 状态显示
              _buildStateIndicator(provider),
              const SizedBox(height: 40),

              // 计时器
              _buildTimer(context, provider),
              const SizedBox(height: 40),

              // 控制按钮
              _buildControls(context, provider),
              const SizedBox(height: 40),

              // 统计
              _buildStats(provider),
            ],
          );
        },
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

  Widget _buildTimer(BuildContext context, PomodoroProvider provider) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度圆环
          SizedBox(
            width: 250,
            height: 250,
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
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '番茄数: ${provider.completedPomodoros}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
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
          onPressed: provider.reset,
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
            onPressed: provider.startWork,
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始工作'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else if (provider.state == PomodoroState.working)
          ElevatedButton.icon(
            onPressed: provider.pause,
            icon: const Icon(Icons.pause),
            label: const Text('暂停'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: provider.resume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('继续'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

        const SizedBox(width: 20),

        // 跳过按钮
        IconButton.filled(
          onPressed: provider.skip,
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
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '今日完成',
              '${provider.completedPomodoros}',
              Icons.check_circle,
            ),
            _buildStatItem(
              '工作时长',
              '${provider.completedPomodoros * 25}分钟',
              Icons.timer,
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
