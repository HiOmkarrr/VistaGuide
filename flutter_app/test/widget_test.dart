// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:vistaguide/main.dart';

void main() {
  testWidgets('App starts and shows home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VistaGuideApp());

    // Verify that the app starts and shows the home page.
    await tester.pumpAndSettle();

    // Check if VistaGuide title is present
    expect(find.text('VistaGuide'), findsOneWidget);

    // Check if bottom navigation is present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
