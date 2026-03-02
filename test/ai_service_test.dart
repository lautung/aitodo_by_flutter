import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NLPService', () {
    final service = NLPService();

    test('parsePriority should parse high and low priority keywords', () {
      expect(service.parsePriority('这是一个紧急任务'), Priority.high);
      expect(service.parsePriority('这个不急，有空再做'), Priority.low);
    });

    test('parseDate should parse relative day expressions', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(service.parseDate('今天完成'), today);
      expect(service.parseDate('明天提交'), today.add(const Duration(days: 1)));
      expect(service.parseDate('3天后提醒我'), today.add(const Duration(days: 3)));
    });

    test('parseTask should extract title, date and priority', () {
      final parsed = service.parseTask('下周三完成紧急工作报告');

      expect(parsed.title, isNotEmpty);
      expect(parsed.hasDate, isTrue);
      expect(parsed.priority, Priority.high);
      expect(parsed.suggestedCategory, TaskCategory.work);
    });
  });
}

