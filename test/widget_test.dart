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

  testWidgets('ConversationSidebar displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Pump a few frames to allow async initialization
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify sidebar elements are present
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('New Conversation'), findsOneWidget);
  });

  testWidgets('New Conversation button is tappable',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find and tap the New Conversation button
    final newConversationButton = find.text('New Conversation');
    expect(newConversationButton, findsOneWidget);

    await tester.tap(newConversationButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // After tapping, the button should still be present
    // (conversation creation is async, so we just verify UI doesn't break)
    expect(find.text('New Conversation'), findsOneWidget);
  });

  testWidgets('Settings button is present', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find the settings floating action button
    final settingsButton = find.byIcon(Icons.settings);
    expect(settingsButton, findsOneWidget);
  });

  testWidgets('App handles missing API key gracefully',
      (WidgetTester tester) async {
    // Temporarily remove API key
    final originalKey = dotenv.env['GEMINI_API_KEY'];
    dotenv.env['GEMINI_API_KEY'] = '';

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // App should still load (error will show when trying to use API)
    expect(find.text('Conversations'), findsOneWidget);

    // Restore original key
    if (originalKey != null) {
      dotenv.env['GEMINI_API_KEY'] = originalKey;
    }
  });
}
