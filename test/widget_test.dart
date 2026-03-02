import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_todo/main.dart';

void main() {
  testWidgets('App renders home screen with FAB', (WidgetTester tester) async {
    // Build app and wait one short frame; avoid pumpAndSettle timeout in this app.
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    // Verify that the app renders the FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
