import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/main.dart';
import 'package:ai_todo/services/compliance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ComplianceService.agreementAcceptedKey: true,
    });
  });

  testWidgets('App renders home screen with FAB', (WidgetTester tester) async {
    // Build app and wait one short frame; avoid pumpAndSettle timeout in this app.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify that the app renders the FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Home command input creates a task with local parser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, '项目周报');
    await tester.tap(find.byTooltip('智能创建任务'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('tasks'), contains('项目周报'));
    expect(find.text('项目周报'), findsWidgets);
  });

  testWidgets('App shows agreement dialog on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('使用前须知'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);

    await tester.tap(find.text('同意并继续'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ComplianceService.agreementAcceptedKey), isTrue);
    expect(find.text('使用前须知'), findsNothing);
  });

  testWidgets('Pomodoro screen fits compact height without overflow', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 640)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('番茄钟'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('开始工作'));
    await tester.pump();

    final exception = tester.takeException();
    expect(find.text('工作中'), findsOneWidget);
    expect(exception, isNull);

    await tester.tap(find.text('暂停'));
    await tester.pump();

    expect(find.text('继续'), findsOneWidget);
    expect(find.text('暂停'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
