import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/ui/ui.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return AppPageScaffold(
          title: '统计',
          subtitle:
              '${provider.filteredCompletedTasks}/${provider.filteredTotalTasks} 已完成',
          leadingIcon: Icons.bar_chart_outlined,
          actions: [
            IconButton.filledTonal(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI摘要',
              onPressed: provider.totalTasks > 0
                  ? () => _showAISummary(context, provider)
                  : null,
            ),
          ],
          child: Column(
            children: [
              _buildTimeFilterChips(context, provider),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: provider.filteredTotalTasks == 0
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (provider.statsTimeFilter ==
                                    StatsTimeFilter.custom &&
                                provider.customStatsDateRange.$1 != null)
                              _buildCustomDateRangeDisplay(context, provider),
                            _buildOverviewCards(context, provider),
                            const SizedBox(height: AppSpacing.md),
                            _buildCompletionRateCard(context, provider),
                            const SizedBox(height: AppSpacing.md),
                            _buildCategoryChart(context, provider),
                            const SizedBox(height: AppSpacing.md),
                            _buildWeeklyTrendChart(context, provider),
                            const SizedBox(height: AppSpacing.md),
                            _buildHeatmapCard(context, provider),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeFilterChips(BuildContext context, TaskProvider provider) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: StatsTimeFilter.values.map((filter) {
            final isSelected = provider.statsTimeFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppFilterChip(
                label: filter.label,
                selected: isSelected,
                onTap: () {
                  if (filter == StatsTimeFilter.custom) {
                    _showCustomDatePicker(context, provider);
                  } else {
                    provider.setStatsTimeFilter(filter);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker(
    BuildContext context,
    TaskProvider provider,
  ) async {
    final currentRange = provider.customStatsDateRange;
    DateTime? startDate = currentRange.$1;
    DateTime? endDate = currentRange.$2;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择时间范围'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('开始日期'),
                subtitle: Text(
                  startDate != null
                      ? DateFormat('yyyy-MM-dd').format(startDate!)
                      : '未选择',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      startDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('结束日期'),
                subtitle: Text(
                  endDate != null
                      ? DateFormat('yyyy-MM-dd').format(endDate!)
                      : '未选择',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      endDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                provider.setCustomStatsDateRange(startDate, endDate);
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.bar_chart_outlined,
      title: '暂无数据',
      message: '添加任务后，这里会显示完成率、分类和趋势。',
    );
  }

  Widget _buildCustomDateRangeDisplay(
    BuildContext context,
    TaskProvider provider,
  ) {
    final startDate = provider.customStatsDateRange.$1;
    final endDate = provider.customStatsDateRange.$2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.date_range,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('yyyy-MM-dd').format(startDate!)} 至 ${DateFormat('yyyy-MM-dd').format(endDate!)}',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, TaskProvider provider) {
    return AppMetricGrid(
      children: [
        AppMetricCard(
          label: '总任务',
          value: provider.filteredTotalTasks.toString(),
          icon: Icons.list_alt,
          color: Colors.blue,
        ),
        AppMetricCard(
          label: '已完成',
          value: provider.filteredCompletedTasks.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        AppMetricCard(
          label: '进行中',
          value: provider.filteredActiveTasks.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCompletionRateCard(BuildContext context, TaskProvider provider) {
    final rate = provider.filteredCompletionRate;
    final percentage = (rate * 100).toStringAsFixed(1);

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '完成率',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: rate * 100,
                            color: Colors.green,
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: (1 - rate) * 100,
                            color: Colors.grey[300]!,
                            radius: 25,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '完成率',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, TaskProvider provider) {
    final tasksByCategory = provider.filteredTasksByCategory;

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '分类统计',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: TaskCategory.values
                            .where((c) => tasksByCategory[c]! > 0)
                            .map((category) {
                              return PieChartSectionData(
                                value: tasksByCategory[category]!.toDouble(),
                                color: category.color,
                                radius: 35,
                                title: '${tasksByCategory[category]}',
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: TaskCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: category.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${category.label}: ${tasksByCategory[category]}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(BuildContext context, TaskProvider provider) {
    final weeklyData = provider.filteredWeeklyCompletionTrend;
    final dateFormat = DateFormat('MM/dd');
    final now = DateTime.now();

    final weekDays = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return dateFormat.format(date);
    });

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  '本周完成趋势',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weekDays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weekDays[index],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: (weeklyData.reduce((a, b) => a > b ? a : b) + 2)
                      .toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        weeklyData.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          weeklyData[index].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.teal,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapCard(BuildContext context, TaskProvider provider) {
    final heatmapData = provider.getCompletionHeatmapData();
    final now = DateTime.now();
    final monthlyData = provider.getTasksByMonth(now.year, now.month);

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  '任务完成热力图',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 月度日历视图
            MonthlyCalendar(
              year: now.year,
              month: now.month,
              data: monthlyData,
              onDayTap: (date) => _showDayTasks(context, provider, date),
            ),
            const SizedBox(height: 20),
            // 年度热力图
            const Text(
              '年度概览',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            HeatmapCalendar(
              data: heatmapData,
              onDayTap: (date) => _showDayTasks(context, provider, date),
              weeksToShow: 26,
            ),
          ],
        ),
      ),
    );
  }

  void _showDayTasks(
    BuildContext context,
    TaskProvider provider,
    DateTime date,
  ) {
    final tasks = provider.getTasksCompletedOn(date);

    showAppBottomSheet(
      context: context,
      title: DateFormat('yyyy-MM-dd').format(date),
      subtitle: '${tasks.length} 个任务已完成',
      child: tasks.isEmpty
          ? const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: '暂无完成的任务',
              message: '当天完成的任务会在这里显示。',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return AppListItem(
                  icon: Icons.check_circle_outline,
                  iconColor: task.category.color,
                  title: task.title,
                  subtitle: task.description,
                  trailing: AppInfoPill(
                    label: task.category.label,
                    color: task.category.color,
                  ),
                );
              },
            ),
    );
  }

  void _showAISummary(BuildContext context, TaskProvider provider) {
    final summary = SummaryService.generateSummary(
      totalTasks: provider.filteredTotalTasks,
      completedTasks: provider.filteredCompletedTasks,
      activeTasks: provider.filteredActiveTasks,
      completionRate: provider.filteredCompletionRate,
      tasksByCategory: provider.filteredTasksByCategory,
      completedByCategory: provider.filteredCompletedByCategory,
      weeklyTrend: provider.filteredWeeklyCompletionTrend,
    );

    final suggestions = SummaryService.generateSuggestions(
      totalTasks: provider.filteredTotalTasks,
      activeTasks: provider.filteredActiveTasks,
      completionRate: provider.filteredCompletionRate,
      tasksByCategory: provider.filteredTasksByCategory,
    );

    showAppBottomSheet(
      context: context,
      title: 'AI任务摘要',
      subtitle: '基于当前筛选范围生成',
      initialChildSize: 0.64,
      minChildSize: 0.42,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          AppSurface(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            child: Text(
              summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: '改进建议', accentColor: Colors.amber),
          ...suggestions.map(
            (suggestion) => AppListItem(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: suggestion,
            ),
          ),
        ],
      ),
    );
  }
}
