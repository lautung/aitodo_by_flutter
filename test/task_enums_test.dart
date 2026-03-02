import 'package:ai_todo/models/task_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskFilter', () {
    test('should have correct values', () {
      expect(TaskFilter.values.length, 3);
      expect(TaskFilter.values, contains(TaskFilter.all));
      expect(TaskFilter.values, contains(TaskFilter.active));
      expect(TaskFilter.values, contains(TaskFilter.completed));
    });
  });

  group('TaskSortType', () {
    test('should have correct values', () {
      expect(TaskSortType.values.length, 3);
      expect(TaskSortType.values, contains(TaskSortType.createdTime));
      expect(TaskSortType.values, contains(TaskSortType.dueDate));
      expect(TaskSortType.values, contains(TaskSortType.priority));
    });
  });

  group('StatsTimeFilter', () {
    test('should have correct values', () {
      expect(StatsTimeFilter.values.length, 6);
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.all));
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.year));
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.month));
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.week));
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.today));
      expect(StatsTimeFilter.values, contains(StatsTimeFilter.custom));
    });

    test('label extension should return correct labels', () {
      expect(StatsTimeFilter.all.label, '全部');
      expect(StatsTimeFilter.year.label, '本年');
      expect(StatsTimeFilter.month.label, '本月');
      expect(StatsTimeFilter.week.label, '本周');
      expect(StatsTimeFilter.today.label, '今日');
      expect(StatsTimeFilter.custom.label, '自定义');
    });
  });
}
