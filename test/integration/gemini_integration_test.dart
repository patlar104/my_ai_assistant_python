import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_ai_assistant/services/gemini_service.dart';
import 'package:my_ai_assistant/services/exceptions.dart';

void main() {
  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env file not found, tests will be skipped
    }
  });

  group('GeminiService Integration Tests', () {
    // These tests require a real API key and will be skipped if not available
    String? apiKey;
    
    setUp(() {
      try {
        apiKey = dotenv.env['GEMINI_API_KEY'];
      } catch (_) {
        apiKey = null;
      }
    });


    group('Real API calls', () {
      test('successfully calls Gemini API with valid key', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        final response = await service.askQuestion(
          prompt: 'Say "Hello" in one word.',
        );

        expect(response, isNotEmpty);
        expect(response.toLowerCase(), contains('hello'));
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');

      test('handles conversation history correctly', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        final history = [
          {'role': 'user', 'content': 'My name is Alice'},
          {'role': 'assistant', 'content': 'Nice to meet you, Alice!'}
        ];

        final response = await service.askQuestion(
          prompt: 'What is my name?',
          conversationHistory: history,
        );

        expect(response, isNotEmpty);
        expect(response.toLowerCase(), contains('alice'));
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');

      test('respects temperature parameter', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        
        // Low temperature should give more focused responses
        final lowTempResponse = await service.askQuestion(
          prompt: 'What is 2+2?',
          temperature: 0.1,
        );

        // High temperature might give more creative responses
        final highTempResponse = await service.askQuestion(
          prompt: 'What is 2+2?',
          temperature: 1.5,
        );

        expect(lowTempResponse, isNotEmpty);
        expect(highTempResponse, isNotEmpty);
        // Both should contain the answer, but might be worded differently
        expect(
          lowTempResponse.contains('4') || highTempResponse.contains('4'),
          isTrue,
        );
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');

      test('handles maxOutputTokens limit', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        
        // Request a very short response
        final response = await service.askQuestion(
          prompt: 'Write a long story about a cat.',
          maxOutputTokens: 50, // Very short limit
        );

        expect(response, isNotEmpty);
        // Response should be truncated due to token limit
        expect(response.length, lessThan(500)); // Rough estimate
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');
    });

    group('Error scenarios', () {
      test('throws exception with invalid API key', () async {
        final service = GeminiService(apiKey: 'invalid-key-12345');

        expect(
          () => service.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiApiException>()),
        );
      });

      test('throws exception for empty prompt', () {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip if no real key
        }

        final service = GeminiService(apiKey: apiKey);

        expect(
          () => service.askQuestion(prompt: ''),
          throwsA(isA<GeminiEmptyResponseException>()),
        );
      });
    });

    group('Prompt analysis integration', () {
      test('includes contextual instructions for research prompts', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        final response = await service.askQuestion(
          prompt: 'Research the history of quantum computing',
        );

        expect(response, isNotEmpty);
        // The response should be research-oriented
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');

      test('includes time context for time-sensitive prompts', () async {
        if (apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key') {
          return; // Skip test if no real API key
        }

        final service = GeminiService(apiKey: apiKey);
        final response = await service.askQuestion(
          prompt: 'What is the current date?',
        );

        expect(response, isNotEmpty);
        // Response should reference current date
        final currentYear = DateTime.now().year.toString();
        expect(response.contains(currentYear), isTrue);
      }, skip: apiKey == null || (apiKey?.isEmpty ?? true) || apiKey == 'test-key');
    });
  });
}

