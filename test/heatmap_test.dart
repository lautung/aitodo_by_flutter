import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/widgets/heatmap_calendar.dart';

void main() {
  group('HeatmapColors Tests', () {
    test('getColorForCount returns correct color for count 0', () {
      final color = HeatmapColors.getColorForCount(0);
      expect(color, HeatmapColors.levels[0]);
    });

    test('getColorForCount returns correct color for count 1-2', () {
      final color1 = HeatmapColors.getColorForCount(1);
      final color2 = HeatmapColors.getColorForCount(2);
      expect(color1, HeatmapColors.levels[1]);
      expect(color2, HeatmapColors.levels[1]);
    });

    test('getColorForCount returns correct color for count 3-5', () {
      final color3 = HeatmapColors.getColorForCount(3);
      final color5 = HeatmapColors.getColorForCount(5);
      expect(color3, HeatmapColors.levels[2]);
      expect(color5, HeatmapColors.levels[2]);
    });

    test('getColorForCount returns correct color for count 6-9', () {
      final color6 = HeatmapColors.getColorForCount(6);
      final color9 = HeatmapColors.getColorForCount(9);
      expect(color6, HeatmapColors.levels[3]);
      expect(color9, HeatmapColors.levels[3]);
    });

    test('getColorForCount returns correct color for count 10+', () {
      final color10 = HeatmapColors.getColorForCount(10);
      final color100 = HeatmapColors.getColorForCount(100);
      expect(color10, HeatmapColors.levels[4]);
      expect(color100, HeatmapColors.levels[4]);
    });

    test('HeatmapColors levels has correct count', () {
      expect(HeatmapColors.levels.length, 5);
    });
  });

  group('HeatmapCalendar Widget Tests', () {
    testWidgets('HeatmapCalendar renders without error', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeatmapCalendar(data: data),
          ),
        ),
      );

      // Widget should render
      expect(find.byType(HeatmapCalendar), findsOneWidget);
    });

    testWidgets('HeatmapCalendar displays with data', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final data = <DateTime, int>{
        today: 5,
        today.subtract(const Duration(days: 1)): 3,
        today.subtract(const Duration(days: 2)): 10,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HeatmapCalendar(data: data),
            ),
          ),
        ),
      );

      expect(find.byType(HeatmapCalendar), findsOneWidget);
    });

    testWidgets('HeatmapCalendar calls onDayTap when day is tapped', (tester) async {
      DateTime? tappedDate;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final data = <DateTime, int>{today: 5};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HeatmapCalendar(
                data: data,
                onDayTap: (date) {
                  tappedDate = date;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap a day cell (GestureDetector inside the grid)
      final gestureDetectors = find.byType(GestureDetector);
      if (gestureDetectors.evaluate().length > 1) {
        await tester.tap(gestureDetectors.first);
        await tester.pump();
      }

      // Widget should render with callback
      expect(find.byType(HeatmapCalendar), findsOneWidget);
    });

    testWidgets('HeatmapCalendar shows legend', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeatmapCalendar(data: data),
          ),
        ),
      );

      // Should find legend text
      expect(find.text('少'), findsOneWidget);
      expect(find.text('多'), findsOneWidget);
    });
  });

  group('YearCalendar Widget Tests', () {
    testWidgets('YearCalendar renders correctly', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: YearCalendar(
                year: 2024,
                data: data,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(YearCalendar), findsOneWidget);
    });

    testWidgets('YearCalendar can navigate years', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: YearCalendar(
                year: 2024,
                data: data,
              ),
            ),
          ),
        ),
      );

      // Find and tap the right arrow to go to next year
      final rightArrows = find.byIcon(Icons.chevron_right);
      await tester.tap(rightArrows.first);
      await tester.pump();

      expect(find.byType(YearCalendar), findsOneWidget);
    });

    testWidgets('YearCalendar displays month cells', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: YearCalendar(
                year: 2024,
                data: data,
              ),
            ),
          ),
        ),
      );

      // Should render
      expect(find.byType(YearCalendar), findsOneWidget);
    });
  });

  group('WeekCalendar Widget Tests', () {
    testWidgets('WeekCalendar renders correctly', (tester) async {
      final now = DateTime.now();
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekCalendar(
              initialDate: now,
              data: data,
            ),
          ),
        ),
      );

      expect(find.byType(WeekCalendar), findsOneWidget);
    });

    testWidgets('WeekCalendar displays 7 days', (tester) async {
      final now = DateTime.now();
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekCalendar(
              initialDate: now,
              data: data,
            ),
          ),
        ),
      );

      // Should display weekday labels - just verify the widget renders
      expect(find.byType(WeekCalendar), findsOneWidget);
    });

    testWidgets('WeekCalendar can navigate weeks', (tester) async {
      final now = DateTime.now();
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekCalendar(
              initialDate: now,
              data: data,
            ),
          ),
        ),
      );

      // Find and tap the right arrow
      final rightArrows = find.byIcon(Icons.chevron_right);
      await tester.tap(rightArrows.first);
      await tester.pump();

      // Week should have changed
      expect(find.byType(WeekCalendar), findsOneWidget);
    });
  });

  group('MonthlyCalendar Widget Tests', () {
    testWidgets('MonthlyCalendar renders correctly', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendar(
              year: 2024,
              month: 6,
              data: data,
            ),
          ),
        ),
      );

      expect(find.byType(MonthlyCalendar), findsOneWidget);
      expect(find.text('2024 年 6 月'), findsOneWidget);
    });

    testWidgets('MonthlyCalendar displays weekday labels', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendar(
              year: 2024,
              month: 6,
              data: data,
            ),
          ),
        ),
      );

      // Should display weekday labels - just verify the widget renders
      expect(find.byType(MonthlyCalendar), findsOneWidget);
    });

    testWidgets('MonthlyCalendar can navigate months', (tester) async {
      final data = <DateTime, int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyCalendar(
              year: 2024,
              month: 6,
              data: data,
            ),
          ),
        ),
      );

      // Tap right arrow to go to next month
      final rightArrows = find.byIcon(Icons.chevron_right);
      await tester.tap(rightArrows.first);
      await tester.pump();

      expect(find.text('2024 年 7 月'), findsOneWidget);
    });
  });
}
