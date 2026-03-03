import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/models/task_enums.dart';

void main() {
  group('TagFilterMode', () {
    test('should have correct labels', () {
      expect(TagFilterMode.or.label, '任一匹配');
      expect(TagFilterMode.and.label, '全部匹配');
    });

    test('should have two values', () {
      expect(TagFilterMode.values.length, 2);
      expect(TagFilterMode.values, contains(TagFilterMode.or));
      expect(TagFilterMode.values, contains(TagFilterMode.and));
    });
  });
}
