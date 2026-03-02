import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../widgets/heatmap_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('日历'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: '热力图'),
                Tab(text: '月历'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 热力图视图
              _buildHeatmapView(provider, heatmapData),
              // 月历视图
              _buildMonthlyView(provider, monthlyData, now.year, now.month),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeatmapView(
      TaskProvider provider, Map<DateTime, int> heatmapData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 统计信息卡片
          _buildStatsCard(provider),
          const SizedBox(height: 24),
          // 热力图
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
        ],
      ),
    );
  }

  Widget _buildMonthlyView(
      TaskProvider provider, Map<DateTime, int> monthlyData, int year, int month) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 月历卡片
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MonthlyCalendar(
                year: year,
                month: month,
                data: monthlyData,
                onDayTap: (date) => _showDayTasks(context, provider, date),
              ),
            ),
          ),
        ],
      ),
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
        .where((t) =>
            t.isCompleted &&
            t.completedAt != null &&
            t.completedAt!.isAfter(yearStart))
        .length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
      String label, String value, IconData icon, Color color) {
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

  void _showDayTasks(
      BuildContext context, TaskProvider provider, DateTime date) {
    final tasks = provider.getTasksCompletedOn(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(date),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tasks.length} 个任务已完成',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              // 任务列表
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '暂无完成的任务',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return ListTile(
                            leading: Icon(
                              Icons.check_circle,
                              color: task.category.color,
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: task.description != null
                                ? Text(
                                    task.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.category.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.category.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: task.category.color,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
