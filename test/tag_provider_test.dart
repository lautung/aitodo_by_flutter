import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_todo/providers/tag_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TagProvider', () {
    test('should have default tags', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.tags.length, 5);
      expect(provider.tags.map((t) => t.name), contains('重要'));
      expect(provider.tags.map((t) => t.name), contains('紧急'));
    });

    test('should add new tag', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = provider.tags.length;
      await provider.addTag('测试标签', Colors.blue);

      expect(provider.tags.length, initialCount + 1);
      expect(provider.tags.last.name, '测试标签');
    });

    test('should update tag color', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final tag = provider.tags.first;
      final newColor = Colors.purple;
      await provider.updateTagColor(tag.id, newColor);

      expect(provider.getTagById(tag.id)?.color, newColor);
    });

    test('should delete tag', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = provider.tags.length;
      final tagId = provider.tags.first.id;
      await provider.deleteTag(tagId);

      expect(provider.tags.length, initialCount - 1);
      expect(provider.getTagById(tagId), isNull);
    });

    test('should get tag by id', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final tag = provider.tags.first;
      final foundTag = provider.getTagById(tag.id);

      expect(foundTag, isNotNull);
      expect(foundTag?.id, tag.id);
      expect(foundTag?.name, tag.name);
    });

    test('should return null for non-existent tag', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = TagProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      final foundTag = provider.getTagById('non_existent_id');

      expect(foundTag, isNull);
    });
  });
}
