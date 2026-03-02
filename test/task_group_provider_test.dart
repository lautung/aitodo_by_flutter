import 'package:ai_todo/models/task_group.dart';
import 'package:ai_todo/providers/task_group_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskGroupProvider', () {
    late TaskGroupProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TaskGroupProvider();
      await provider.initialize();
    });

    test('initial state should be empty groups', () {
      expect(provider.groups, isEmpty);
      expect(provider.selectedGroupId, isNull);
      expect(provider.selectedGroup, isNull);
    });

    test('addGroup should add group and persist', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );

      await provider.addGroup(group);

      expect(provider.groups.length, 1);
      expect(provider.groups.first.name, '工作');
    });

    test('updateGroup should update existing group', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '原名称',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      final updated = group.copyWith(name: '新名称');
      await provider.updateGroup(updated);

      expect(provider.groups.first.name, '新名称');
    });

    test('deleteGroup should remove group', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '待删除',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      await provider.deleteGroup('group-1');

      expect(provider.groups, isEmpty);
    });

    test('deleteGroup should clear selectedGroupId if deleted group was selected', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);
      provider.selectGroup('group-1');

      await provider.deleteGroup('group-1');

      expect(provider.selectedGroupId, isNull);
    });

    test('selectGroup should set selectedGroupId', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      provider.selectGroup('group-1');

      expect(provider.selectedGroupId, 'group-1');
      expect(provider.selectedGroup, isNotNull);
      expect(provider.selectedGroup!.name, '工作');
    });

    test('selectGroup with null should deselect', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);
      provider.selectGroup('group-1');

      provider.selectGroup(null);

      expect(provider.selectedGroupId, isNull);
      expect(provider.selectedGroup, isNull);
    });

    test('getGroupById should return correct group', () async {
      final group1 = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      final group2 = TaskGroup(
        id: 'group-2',
        name: '生活',
        color: Colors.blue,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group1);
      await provider.addGroup(group2);

      final found = provider.getGroupById('group-2');

      expect(found, isNotNull);
      expect(found!.name, '生活');
    });

    test('getGroupById should return null for non-existent id', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      final found = provider.getGroupById('non-existent');

      expect(found, isNull);
    });

    test('selectedGroup should return first group if selectedGroupId not found', () async {
      final group1 = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group1);
      provider.selectGroup('non-existent-id');

      // Should fall back to first group
      expect(provider.selectedGroup, isNotNull);
      expect(provider.selectedGroup!.name, '工作');
    });

    test('groups should be unmodifiable', () async {
      final group = TaskGroup(
        id: 'group-1',
        name: '工作',
        color: Colors.red,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      expect(() => provider.groups.add(group), throwsUnsupportedError);
    });

    test('should persist groups across reinitialization', () async {
      final group = TaskGroup(
        id: 'persist-test',
        name: '持久化测试',
        color: Colors.green,
        createdAt: DateTime.now(),
      );
      await provider.addGroup(group);

      // Create new provider instance
      final newProvider = TaskGroupProvider();
      await newProvider.initialize();

      expect(newProvider.groups.length, 1);
      expect(newProvider.groups.first.name, '持久化测试');
      newProvider.dispose();
    });
  });
}
