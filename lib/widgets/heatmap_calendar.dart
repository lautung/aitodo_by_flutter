import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/lunar_service.dart';

/// 热力图颜色等级
class HeatmapColors {
  static const List<Color> levels = [
    Color(0xFFEBEDF0), // 0 - 无数据
    Color(0xFF9BE9A8), // 1-2 - 少量
    Color(0xFF40C463), // 3-5 - 适量
    Color(0xFF30A14E), // 6-9 - 较多
    Color(0xFF216E39), // 10+ - 很多
  ];

  static Color getColorForCount(int count) {
    if (count == 0) return levels[0];
    if (count <= 2) return levels[1];
    if (count <= 5) return levels[2];
    if (count <= 9) return levels[3];
    return levels[4];
  }
}

/// 热力图组件 - 类似 GitHub 贡献图
class HeatmapCalendar extends StatefulWidget {
  final Map<DateTime, int> data;
  final Function(DateTime)? onDayTap;
  final int weeksToShow;

  const HeatmapCalendar({
    super.key,
    required this.data,
    this.onDayTap,
    this.weeksToShow = 52,
  });

  @override
  State<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends State<HeatmapCalendar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 计算起始日期（weeksToShow 周前的周日）
    final startDate = today.subtract(Duration(days: today.weekday % 7));
    final adjustedStart = startDate.subtract(Duration(days: (widget.weeksToShow - 1) * 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 月份标签
        _buildMonthLabels(adjustedStart, today),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 星期标签
            _buildWeekdayLabels(),
            const SizedBox(width: 4),
            // 热力图网格
            Expanded(
              child: _buildHeatmapGrid(adjustedStart, today),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 图例
        _buildLegend(),
      ],
    );
  }

  Widget _buildMonthLabels(DateTime startDate, DateTime today) {
    final months = <Widget>[];
    var currentMonth = -1;
    var currentDate = startDate;

    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      if (currentDate.month != currentMonth) {
        currentMonth = currentDate.month;
        months.add(
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('M').format(currentDate),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      } else {
        months.add(const SizedBox(width: 50));
      }
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(children: months),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Column(
      children: List.generate(7, (index) {
        // 只显示周日、一、三、五
        if (index == 0 || index == 2 || index == 4 || index == 6) {
          return SizedBox(
            height: 14,
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          );
        }
        return const SizedBox(height: 14);
      }),
    );
  }

  Widget _buildHeatmapGrid(DateTime startDate, DateTime today) {
    final weeks = <Widget>[];

    for (int week = 0; week < widget.weeksToShow; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      final days = <Widget>[];

      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final isFuture = date.isAfter(today);
        final count = isFuture ? 0 : (widget.data[DateTime(date.year, date.month, date.day)] ?? 0);

        days.add(
          GestureDetector(
            onTap: (!isFuture && widget.onDayTap != null)
                ? () => widget.onDayTap!(date)
                : null,
            child: Tooltip(
              message: '${DateFormat('yyyy-MM-dd').format(date)}: $count 个任务',
              child: Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isFuture ? Colors.grey[200] : HeatmapColors.getColorForCount(count),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      weeks.add(
        Column(children: days),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(children: weeks),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '少',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        ...HeatmapColors.levels.map((color) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            )),
        const SizedBox(width: 4),
        Text(
          '多',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// 年度日历视图
class YearCalendar extends StatefulWidget {
  final int year;
  final Map<DateTime, int> data;
  final Function(DateTime)? onMonthTap;
  final Function(DateTime)? onDayTap;

  const YearCalendar({
    super.key,
    required this.year,
    required this.data,
    this.onMonthTap,
    this.onDayTap,
  });

  @override
  State<YearCalendar> createState() => _YearCalendarState();
}

class _YearCalendarState extends State<YearCalendar> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildYearGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _year--),
        ),
        Text(
          '$_year 年',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _year++),
        ),
      ],
    );
  }

  Widget _buildYearGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        return _buildMonthCell(month);
      },
    );
  }

  Widget _buildMonthCell(int month) {
    final now = DateTime.now();
    final isCurrentMonth = _year == now.year && month == now.month;
    final daysInMonth = DateTime(_year, month + 1, 0).day;

    // 统计当月任务数
    var taskCount = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final dateKey = DateTime(_year, month, day);
      taskCount += widget.data[dateKey] ?? 0;
    }

    return GestureDetector(
      onTap: widget.onMonthTap != null
          ? () => widget.onMonthTap!(DateTime(_year, month, 1))
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: taskCount > 0
              ? HeatmapColors.getColorForCount(taskCount).withValues(alpha: 0.3)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: isCurrentMonth
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$month 月',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
                color: isCurrentMonth
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$taskCount 任务',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 周日历视图
class WeekCalendar extends StatefulWidget {
  final DateTime initialDate;
  final Map<DateTime, int> data;
  final Function(DateTime)? onDayTap;

  const WeekCalendar({
    super.key,
    required this.initialDate,
    required this.data,
    this.onDayTap,
  });

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    // 获取本周的起始日期（周日）
    _currentWeekStart = widget.initialDate.subtract(
      Duration(days: widget.initialDate.weekday % 7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildWeekView(),
      ],
    );
  }

  Widget _buildHeader() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final formatter = DateFormat('MM/dd');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
            });
          },
        ),
        Text(
          '${formatter.format(_currentWeekStart)} - ${formatter.format(weekEnd)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Row(
      children: List.generate(7, (index) {
        final date = _currentWeekStart.add(Duration(days: index));
        final dateKey = DateTime(date.year, date.month, date.day);
        final count = widget.data[dateKey] ?? 0;
        final isToday = date.isAtSameMomentAs(today);
        final isFuture = date.isAfter(today);

        return Expanded(
          child: GestureDetector(
            onTap: (!isFuture && widget.onDayTap != null)
                ? () => widget.onDayTap!(date)
                : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isToday
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : (count > 0
                        ? HeatmapColors.getColorForCount(count).withValues(alpha: 0.2)
                        : Colors.grey[50]),
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    ['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isFuture
                          ? Colors.grey[400]
                          : (isToday
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (count > 0)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: HeatmapColors.getColorForCount(count),
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 日视图
class DayCalendar extends StatelessWidget {
  final DateTime date;
  final Map<DateTime, int> data;
  final List<dynamic> tasks;
  final Function(dynamic)? onTaskTap;
  final LunarService lunarService;

  const DayCalendar({
    super.key,
    required this.date,
    required this.data,
    required this.tasks,
    this.onTaskTap,
    required this.lunarService,
  });

  @override
  Widget build(BuildContext context) {
    final lunarInfo = lunarService.getLunarInfo(date);
    final huangliInfo = lunarService.getHuangliInfo(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(context, lunarInfo),
          const SizedBox(height: 16),
          _buildHuangliCard(context, huangliInfo),
          const SizedBox(height: 16),
          _buildTaskSummary(context),
        ],
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, LunarInfo lunarInfo) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isToday ? '今天' : DateFormat('EEEE').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('yyyy年MM月dd日').format(date),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '农历: ${lunarInfo.monthName}${lunarInfo.dayName} (${lunarInfo.zodiac}年)${lunarInfo.isLeapMonth ? " 闰月" : ""}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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

  Widget _buildHuangliCard(BuildContext context, HuangliInfo info) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_stories, size: 18, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '黄历',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLuckIndicator(info.luck),
                const SizedBox(width: 16),
                Expanded(child: Text(info.chong, style: TextStyle(color: Colors.grey[600]))),
                Expanded(child: Text(info.sha, style: TextStyle(color: Colors.grey[600]))),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          const Text(
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
                        info.yi,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cancel, size: 14, color: Colors.red[600]),
                          const SizedBox(width: 4),
                          const Text(
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
                        info.ji,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
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

  Widget _buildLuckIndicator(String luck) {
    Color color;
    IconData icon;
    switch (luck) {
      case '吉':
        color = Colors.green;
        icon = Icons.sentiment_satisfied;
        break;
      case '凶':
        color = Colors.red;
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        color = Colors.grey;
        icon = Icons.sentiment_neutral;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            luck,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSummary(BuildContext context) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final count = data[dateKey] ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task_alt, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '任务概览',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count 个任务',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (tasks.isNotEmpty) ...[
              const Divider(height: 24),
              ...tasks.map((task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: task.category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        '暂无任务',
                        style: TextStyle(color: Colors.grey[600]),
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
}

/// 月度日历组件（增强版，支持农历）
class MonthlyCalendar extends StatefulWidget {
  final int year;
  final int month;
  final Map<DateTime, int> data;
  final Function(DateTime)? onDayTap;
  final bool showLunar;
  final LunarService? lunarService;

  const MonthlyCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    this.onDayTap,
    this.showLunar = true,
    this.lunarService,
  });

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late int _year;
  late int _month;
  late LunarService _lunarService;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
    _lunarService = widget.lunarService ?? LunarService();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 月份切换头部
        _buildHeader(),
        const SizedBox(height: 16),
        // 星期标签
        _buildWeekdayLabels(),
        const SizedBox(height: 8),
        // 日历网格
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _goToPreviousMonth,
        ),
        Text(
          '$_year 年 $_month 月',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _canGoToNextMonth ? _goToNextMonth : null,
        ),
      ],
    );
  }

  bool get _canGoToNextMonth {
    final now = DateTime.now();
    return _year < now.year || (_year == now.year && _month < now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_year, _month, 1);
    final lastDayOfMonth = DateTime(_year, _month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final rows = <Widget>[];
    var dayCounter = 1 - firstWeekday;

    while (dayCounter <= daysInMonth) {
      final cells = <Widget>[];
      for (int i = 0; i < 7; i++) {
        if (dayCounter < 1 || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 50)));
        } else {
          final date = DateTime(_year, _month, dayCounter);
          final dateKey = DateTime(date.year, date.month, date.day);
          final count = widget.data[dateKey] ?? 0;
          final isToday = date.isAtSameMomentAs(today);
          final isFuture = date.isAfter(today);

          // 获取农历信息
          String? lunarDay;
          if (widget.showLunar && !isFuture) {
            try {
              final lunarInfo = _lunarService.getLunarInfo(date);
              lunarDay = lunarInfo.dayName == '初一'
                  ? lunarInfo.monthName.substring(1)
                  : lunarInfo.dayName.substring(1);
            } catch (e) {
              // 忽略错误
            }
          }

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: (!isFuture && widget.onDayTap != null)
                    ? () => widget.onDayTap!(date)
                    : null,
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.grey[100]
                        : (count > 0
                            ? HeatmapColors.getColorForCount(count).withValues(alpha: 0.3)
                            : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayCounter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isFuture
                              ? Colors.grey[400]
                              : (isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87),
                        ),
                      ),
                      if (lunarDay != null)
                        Text(
                          lunarDay,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (count > 0)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: HeatmapColors.getColorForCount(count),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        dayCounter++;
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }
}
