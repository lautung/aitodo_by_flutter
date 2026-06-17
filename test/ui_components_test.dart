import 'package:ai_todo/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppFilterChip renders count and handles taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppFilterChip(
              label: '今天',
              count: 3,
              selected: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('今天'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('今天'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppPageScaffold and metric card render in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppPageScaffold(
          title: '统计',
          subtitle: '低噪音数据视图',
          leadingIcon: Icons.bar_chart_outlined,
          child: AppMetricCard(
            label: '已完成',
            value: '12',
            icon: Icons.check_circle_outline,
          ),
        ),
      ),
    );

    expect(find.text('统计'), findsOneWidget);
    expect(find.text('低噪音数据视图'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('AppListItem handles taps and trailing content', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSurface(
            padding: EdgeInsets.zero,
            child: AppListItem(
              icon: Icons.settings_outlined,
              title: '设置项',
              subtitle: '说明文字',
              trailing: const AppInfoPill(label: '开', color: Colors.teal),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('设置项'), findsOneWidget);
    expect(find.text('说明文字'), findsOneWidget);
    expect(find.text('开'), findsOneWidget);

    await tester.tap(find.text('设置项'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
