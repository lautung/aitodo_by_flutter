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
}
