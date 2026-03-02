import 'package:flutter/material.dart';

/// 紧凑型热力图小组件 - 用于首页展示最近几周数据
class HeatmapMini extends StatelessWidget {
  final Map<DateTime, int> data;
  final int weeksToShow;
  final VoidCallback? onTap;

  const HeatmapMini({
    super.key,
    required this.data,
    this.weeksToShow = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 最近 weeksToShow 周的数据
    final startDate = today.subtract(Duration(days: today.weekday % 7));
    final adjustedStart = startDate.subtract(Duration(days: (weeksToShow - 1) * 7));

    // 计算最大完成数用于归一化
    int maxCount = 1;
    for (int i = 0; i < weeksToShow * 7; i++) {
      final date = adjustedStart.add(Duration(days: i));
      if (!date.isAfter(today)) {
        final count = data[DateTime(date.year, date.month, date.day)] ?? 0;
        if (count > maxCount) maxCount = count;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '任务完成趋势',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 紧凑型热力图
            SizedBox(
              height: 50,
              child: _buildCompactHeatmap(adjustedStart, today, maxCount),
            ),
            const SizedBox(height: 8),
            // 图例
            _buildCompactLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeatmap(DateTime startDate, DateTime today, int maxCount) {
    return Row(
      children: List.generate(weeksToShow * 7, (index) {
        final date = startDate.add(Duration(days: index));
        final isFuture = date.isAfter(today);
        final dateKey = DateTime(date.year, date.month, date.day);
        final count = isFuture ? 0 : (data[dateKey] ?? 0);

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.grey[100]
                  : _getColorForCount(count, maxCount),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Color _getColorForCount(int count, int maxCount) {
    if (count == 0) return Colors.grey[200]!;
    final ratio = count / maxCount;
    if (ratio <= 0.25) return const Color(0xFF9BE9A8);
    if (ratio <= 0.5) return const Color(0xFF40C463);
    if (ratio <= 0.75) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  Widget _buildCompactLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '少',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF9BE9A8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF40C463),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF216E39),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '多',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
