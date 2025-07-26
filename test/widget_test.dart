// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arogya_sos_app/main.dart'; // Ensure this import points to your main app file

void main() {
  testWidgets('ArogyaSOSApp builds and displays Emergency SOS screen initially', (WidgetTester tester) async {
    // Build our ArogyaSOSApp and trigger a frame.
    await tester.pumpWidget(const ArogyaSOSApp());

    // Verify that the 'Emergency SOS' app bar title is present on the initial screen.
    expect(find.text('Emergency SOS'), findsOneWidget);

    // You can add more tests here, for example:
    // Verify that the SOS button is present.
    expect(find.text('SOS\nEmergency'), findsOneWidget);

    // Verify that the 'Medicine' tab icon is present (from BottomNavigationBar).
    expect(find.byIcon(Icons.medication), findsOneWidget);

    // Tap on the 'Medicine' tab and verify the screen changes.
    await tester.tap(find.byIcon(Icons.medication));
    await tester.pumpAndSettle(); // Wait for animations to complete

    // Verify that the 'Medicine Finder' app bar title is now present.
    expect(find.text('Medicine Finder'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsNothing); // Ensure old title is gone
  });
}