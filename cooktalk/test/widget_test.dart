import 'package:cooktalk/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts and displays home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app starts at the home screen.
    expect(find.text('쿡톡'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}