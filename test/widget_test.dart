// Flutter widget tests for My AI Assistant
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_ai_assistant/main.dart';

void main() {
  setUpAll(() async {
    // Load a test .env file or set up test environment
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // If .env doesn't exist, set a test key directly
      // Note: In a real test environment, you might want to mock the dotenv
      dotenv.env['GEMINI_API_KEY'] = 'test-key-for-testing';
    }
  });

  testWidgets('App loads and displays HomeScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    // Pump a few frames to allow async initialization, but don't wait indefinitely
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the Conversations sidebar is present
    expect(find.text('Conversations'), findsOneWidget);
    
    // Verify that the New Conversation button is present
    expect(find.text('New Conversation'), findsOneWidget);
  });

  testWidgets('ConversationSidebar displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Pump a few frames to allow async initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify sidebar elements are present
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('New Conversation'), findsOneWidget);
  });
}
