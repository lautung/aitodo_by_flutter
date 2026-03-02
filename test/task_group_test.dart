import 'package:ai_todo/models/task_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskGroup', () {
    test('create should generate unique id and set default values', () {
      final group1 = TaskGroup.create(name: '工作', color: Colors.red);
      final group2 = TaskGroup.create(name: '生活', color: Colors.blue);

      expect(group1.id, isNotEmpty);
      expect(group2.id, isNotEmpty);
      expect(group1.id, isNot(equals(group2.id)));
      expect(group1.name, '工作');
      expect(group1.color, Colors.red);
      expect(group1.createdAt, isNotNull);
      expect(group1.sortOrder, 0);
    });

    test('copyWith should create new instance with updated values', () {
      final original = TaskGroup.create(name: '原名称', color: Colors.red);
      final copied = original.copyWith(name: '新名称', color: Colors.blue);

      expect(copied.id, original.id);
      expect(copied.name, '新名称');
      expect(copied.color, Colors.blue);
      expect(copied.createdAt, original.createdAt);
    });

    test('toJson should serialize all fields correctly', () {
      final createdAt = DateTime(2026, 3, 1, 10, 30);
      final group = TaskGroup(
        id: 'test-id-123',
        name: '测试分组',
        color: Color(0xFFFF0000),
        iconName: 'work',
        createdAt: createdAt,
        sortOrder: 1,
      );

      final json = group.toJson();

      expect(json['id'], 'test-id-123');
      expect(json['name'], '测试分组');
      expect(json['color'], Color(0xFFFF0000).toARGB32());
      expect(json['iconName'], 'work');
      expect(json['sortOrder'], 1);
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'id': 'test-id-456',
        'name': '从JSON创建',
        'color': 0xFF00FF00,
        'iconName': 'home',
        'createdAt': '2026-03-01T10:30:00.000',
        'sortOrder': 2,
      };

      final group = TaskGroup.fromJson(json);

      expect(group.id, 'test-id-456');
      expect(group.name, '从JSON创建');
      expect(group.color, Color(0xFF00FF00));
      expect(group.iconName, 'home');
      expect(group.sortOrder, 2);
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'minimal-id',
        'name': '最小分组',
        'color': 0xFF000000,
        'createdAt': '2026-03-01T10:30:00.000',
      };

      final group = TaskGroup.fromJson(json);

      expect(group.id, 'minimal-id');
      expect(group.name, '最小分组');
      expect(group.iconName, isNull);
      expect(group.sortOrder, 0);
    });

    test('roundtrip: toJson -> fromJson should preserve data', () {
      final original = TaskGroup.create(
        name: '往返测试',
        color: Colors.purple,
        iconName: 'star',
      );

      final json = original.toJson();
      final restored = TaskGroup.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.color.toARGB32(), original.color.toARGB32());
      expect(restored.iconName, original.iconName);
      expect(restored.sortOrder, original.sortOrder);
    });
  });
}
