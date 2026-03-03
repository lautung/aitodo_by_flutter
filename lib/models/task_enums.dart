/// 任务过滤类型
enum TaskFilter {
  all,
  active,
  completed,
}

/// 任务排序类型
enum TaskSortType {
  createdTime,
  dueDate,
  priority,
}

/// 标签筛选模式
enum TagFilterMode {
  or,  // 任一匹配
  and, // 全部匹配
}

extension TagFilterModeExtension on TagFilterMode {
  String get label {
    switch (this) {
      case TagFilterMode.or:
        return '任一匹配';
      case TagFilterMode.and:
        return '全部匹配';
    }
  }
}

/// 统计时间范围过滤器
enum StatsTimeFilter {
  all,
  year,
  month,
  week,
  today,
  custom, // 自定义时间范围
}

extension StatsTimeFilterExtension on StatsTimeFilter {
  String get label {
    switch (this) {
      case StatsTimeFilter.all:
        return '全部';
      case StatsTimeFilter.year:
        return '本年';
      case StatsTimeFilter.month:
        return '本月';
      case StatsTimeFilter.week:
        return '本周';
      case StatsTimeFilter.today:
        return '今日';
      case StatsTimeFilter.custom:
        return '自定义';
    }
  }
}
