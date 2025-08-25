// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dark_room/main.dart';
import 'package:dark_room/game/ui/menu/main_menu_screen.dart';

void main() {
  testWidgets('DarkRoomApp initializes and renders menu screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DarkRoomApp());

    // Verify that the app initializes with correct title
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify that the GameNavigator widget is present
    expect(find.byType(GameNavigator), findsOneWidget);
    
    // Verify that the MainMenuScreen widget is present (default state)
    expect(find.byType(MainMenuScreen), findsOneWidget);
    
    // Verify that the Scaffold has black background
    final Scaffold scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.backgroundColor, equals(Colors.black));
  });

  testWidgets('DarkRoomApp has correct theme configuration', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DarkRoomApp());

    // Get the MaterialApp widget
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    
    // Verify correct app title
    expect(app.title, equals('Dark Room'));
    
    // Verify debug banner is disabled
    expect(app.debugShowCheckedModeBanner, isFalse);
    
    // Verify dark theme is set
    expect(app.theme, equals(ThemeData.dark()));
  });
}
