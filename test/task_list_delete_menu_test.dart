import 'dart:convert';

import 'package:ai_todo/main.dart';
import 'package:ai_todo/models/task.dart';
import 'package:ai_todo/services/compliance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Task buildTask() {
    return Task(
      id: 'task-delete-menu',
      title: '菜单删除测试任务',
      createdAt: DateTime(2026, 6, 15, 9),
    );
  }

  void seedTasks(List<Task> tasks) {
    SharedPreferences.setMockInitialValues({
      ComplianceService.agreementAcceptedKey: true,
      'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
      'deleted_tasks': '[]',
    });
  }

  Future<void> pumpTaskList(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('delete menu cancel keeps task in the list', (tester) async {
    seedTasks([buildTask()]);

    await pumpTaskList(tester);

    expect(find.text('菜单删除测试任务'), findsOneWidget);

    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除任务'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('菜单删除测试任务'), findsOneWidget);
  });

  testWidgets('delete menu confirmation removes task from the list', (
    tester,
  ) async {
    seedTasks([buildTask()]);

    await pumpTaskList(tester);

    expect(find.text('菜单删除测试任务'), findsOneWidget);

    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除任务'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tasks'), '[]');
    expect(find.text('任务详情'), findsNothing);
    expect(find.text('菜单删除测试任务'), findsNothing);
    expect(find.text('任务已删除'), findsOneWidget);
  });
}
