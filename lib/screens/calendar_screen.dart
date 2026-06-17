import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../widgets/heatmap_calendar.dart';
import '../services/lunar_service.dart';
import '../widgets/ui/ui.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LunarService _lunarService = LunarService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final heatmapData = provider.getCompletionHeatmapData();
        final now = DateTime.now();
        final monthlyData = provider.getTasksByMonth(now.year, now.month);

        return AppPageScaffold(
          title: '日历',
          subtitle: DateFormat('yyyy年M月d日').format(now),
          leadingIcon: Icons.calendar_today_outlined,
          child: Column(
            children: [
              AppSurface(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  tabs: const [
                    Tab(text: '年'),
                    Tab(text: '月'),
                    Tab(text: '周'),
                    Tab(text: '日'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildYearView(provider, heatmapData, now),
                    _buildMonthlyView(
                      provider,
                      monthlyData,
                      now.year,
                      now.month,
                    ),
                    _buildWeekView(provider, heatmapData, now),
                    _buildDayView(provider, heatmapData, now, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearView(
    TaskProvider provider,
    Map<DateTime, int> heatmapData,
    DateTime now,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计信息卡片
          _buildStatsCard(provider),
          const SizedBox(height: 24),
          // 年度热力图
          AppSurface(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grid_view, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        '年度完成热力图',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HeatmapCalendar(
                    data: heatmapData,
                    onDayTap: (date) => _showDayTasks(context, provider, date),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 年日历视图
          AppSurface(
            child: Padding(
              padding: EdgeInsets.zero,
              child: YearCalendar(
                year: now.year,
                data: heatmapData,
                onMonthTap: (date) {
                  // 切换到月视图
                  _tabController.animateTo(1);
                },
                onDayTap: (date) => _showDayTasks(context, provider, date),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView(
    TaskProvider provider,
    Map<DateTime, int> monthlyData,
    int year,
    int month,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 月历卡片
          AppSurface(
            child: Padding(
              padding: EdgeInsets.zero,
              child: MonthlyCalendar(
                year: year,
                month: month,
                data: monthlyData,
                onDayTap: (date) => _showDayTasks(context, provider, date),
                showLunar: true,
                lunarService: _lunarService,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 当日黄历信息
          _buildTodayHuangliCard(),
        ],
      ),
    );
  }

  Widget _buildTodayHuangliCard() {
    final now = DateTime.now();
    final lunarInfo = _lunarService.getLunarInfo(now);
    final huangliInfo = _lunarService.getHuangliInfo(now);

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  '今日黄历',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getLuckColor(
                      huangliInfo.luck,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    huangliInfo.luck,
                    style: TextStyle(
                      color: _getLuckColor(huangliInfo.luck),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '农历: ${lunarInfo.monthName}${lunarInfo.dayName} (${lunarInfo.zodiac}年)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (lunarInfo.solarTerm != null || lunarInfo.festival != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (lunarInfo.solarTerm != null)
                      _buildTag(lunarInfo.solarTerm!, Colors.orange),
                    if (lunarInfo.festival != null)
                      _buildTag(lunarInfo.festival!, Colors.red),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '宜',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        huangliInfo.yi,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cancel, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            '忌',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        huangliInfo.ji,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getLuckColor(String luck) {
    switch (luck) {
      case '吉':
        return Colors.green;
      case '凶':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWeekView(
    TaskProvider provider,
    Map<DateTime, int> heatmapData,
    DateTime now,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 周日历视图
          AppSurface(
            child: Padding(
              padding: EdgeInsets.zero,
              child: WeekCalendar(
                initialDate: now,
                data: heatmapData,
                onDayTap: (date) => _showDayTasks(context, provider, date),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 周任务统计
          _buildWeekStats(provider, heatmapData, now),
        ],
      ),
    );
  }

  Widget _buildWeekStats(
    TaskProvider provider,
    Map<DateTime, int> heatmapData,
    DateTime now,
  ) {
    // 获取本周的任务统计
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    var completedTasks = 0;

    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      final count = heatmapData[dateKey] ?? 0;
      completedTasks += count;
    }

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '本周完成',
              completedTasks.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem('本周天数', '7', Icons.calendar_today, Colors.blue),
            _buildStatItem(
              '日均',
              (completedTasks / 7).toStringAsFixed(1),
              Icons.trending_up,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayView(
    TaskProvider provider,
    Map<DateTime, int> heatmapData,
    DateTime now,
    TaskProvider taskProvider,
  ) {
    final selectedDate = now;

    return DayCalendar(
      date: selectedDate,
      data: heatmapData,
      tasks: taskProvider.allTasks.where((task) {
        final taskDate = task.dueDate;
        if (taskDate == null) return false;
        return taskDate.year == selectedDate.year &&
            taskDate.month == selectedDate.month &&
            taskDate.day == selectedDate.day;
      }).toList(),
      onTaskTap: (task) {
        // 处理任务点击
      },
      lunarService: _lunarService,
    );
  }

  Widget _buildStatsCard(TaskProvider provider) {
    final heatmapData = provider.getCompletionHeatmapData();
    int totalCompleted = 0;
    int daysWithTasks = 0;

    for (final count in heatmapData.values) {
      totalCompleted += count;
      if (count > 0) daysWithTasks++;
    }

    // 计算本年完成数
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearTotal = provider.allTasks
        .where(
          (t) =>
              t.isCompleted &&
              t.completedAt != null &&
              t.completedAt!.isAfter(yearStart),
        )
        .length;

    return AppSurface(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              '今年完成',
              yearTotal.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem(
              '累计完成',
              totalCompleted.toString(),
              Icons.trending_up,
              Colors.blue,
            ),
            _buildStatItem(
              '活跃天数',
              daysWithTasks.toString(),
              Icons.calendar_today,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showDayTasks(
    BuildContext context,
    TaskProvider provider,
    DateTime date,
  ) {
    final tasks = provider.getTasksCompletedOn(date);

    final allDayTasks = provider.allTasks.where((task) {
      final taskDate = task.dueDate;
      if (taskDate == null) return false;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
    final lunarInfo = _lunarService.getLunarInfo(date);

    showAppBottomSheet(
      context: context,
      title: DateFormat('yyyy-MM-dd').format(date),
      subtitle: '农历: ${lunarInfo.monthName}${lunarInfo.dayName}',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _buildTaskStatChip(
                  '已完成',
                  tasks.length.toString(),
                  Colors.green,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildTaskStatChip(
                  '待完成',
                  (allDayTasks.length - tasks.length).toString(),
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: allDayTasks.isEmpty
                ? const AppEmptyState(
                    icon: Icons.inbox_outlined,
                    title: '暂无任务',
                    message: '当天有截止日期的任务会在这里显示。',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: allDayTasks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final task = allDayTasks[index];
                      return AppListItem(
                        icon: task.isCompleted
                            ? Icons.check_circle_outline
                            : Icons.circle_outlined,
                        iconColor: task.isCompleted
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                        title: task.title,
                        subtitle: task.description,
                        trailing: AppInfoPill(
                          label: task.category.label,
                          color: task.category.color,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
