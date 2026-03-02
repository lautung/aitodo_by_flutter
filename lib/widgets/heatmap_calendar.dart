import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
class HeatmapCalendar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 计算起始日期（weeksToShow 周前的周日）
    final startDate = today.subtract(Duration(days: today.weekday % 7));
    final adjustedStart = startDate.subtract(Duration(days: (weeksToShow - 1) * 7));

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
      child: Row(children: months),
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

    for (int week = 0; week < weeksToShow; week++) {
      final weekStart = startDate.add(Duration(days: week * 7));
      final days = <Widget>[];

      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final isFuture = date.isAfter(today);
        final count = isFuture ? 0 : (data[DateTime(date.year, date.month, date.day)] ?? 0);

        days.add(
          GestureDetector(
            onTap: (!isFuture && onDayTap != null)
                ? () => onDayTap!(date)
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
      scrollDirection: Axis.horizontal,
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

/// 月度日历组件
class MonthlyCalendar extends StatefulWidget {
  final int year;
  final int month;
  final Map<DateTime, int> data;
  final Function(DateTime)? onDayTap;

  const MonthlyCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    this.onDayTap,
  });

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
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
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final date = DateTime(_year, _month, dayCounter);
          final dateKey = DateTime(date.year, date.month, date.day);
          final count = widget.data[dateKey] ?? 0;
          final isToday = date.isAtSameMomentAs(today);
          final isFuture = date.isAfter(today);

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: (!isFuture && widget.onDayTap != null)
                    ? () => widget.onDayTap!(date)
                    : null,
                child: Container(
                  height: 40,
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
                      if (count > 0)
                        Container(
                          width: 6,
                          height: 6,
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
