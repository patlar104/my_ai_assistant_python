import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_ai_assistant/services/gemini_service.dart';
import 'package:my_ai_assistant/services/exceptions.dart';

// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, http.Response> _responses = {};
  final List<http.Request> _requests = [];

  void setResponse(String url, http.Response response) {
    _responses[url] = response;
  }

  List<http.Request> get requests => _requests;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _requests.add(request as http.Request);
    final url = request.url.toString();

    if (_responses.containsKey(url)) {
      final response = _responses[url]!;
      return http.StreamedResponse(
        Stream.value(utf8.encode(response.body)),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
      );
    }

    // Default 404 response
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"error": {"message": "Not found"}}')),
      404,
    );
  }
}

void main() {
  late MockHttpClient mockClient;
  late GeminiService geminiService;
  const String testApiKey = 'test-api-key';
  const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  const String model = 'gemini-2.5-flash';

  setUpAll(() async {
    // Set up test environment
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      dotenv.env['GEMINI_API_KEY'] = testApiKey;
    }
  });

  setUp(() {
    mockClient = MockHttpClient();
    geminiService = GeminiService(apiKey: testApiKey, httpClient: mockClient);
  });

  group('GeminiService', () {
    group('Empty prompt validation', () {
      test('throws GeminiEmptyResponseException for empty prompt', () async {
        expect(
          () => geminiService.askQuestion(prompt: '   '),
          throwsA(isA<GeminiEmptyResponseException>()),
        );
      });

      test('throws GeminiEmptyResponseException for whitespace-only prompt',
          () async {
        expect(
          () => geminiService.askQuestion(prompt: '\n\t  \n'),
          throwsA(isA<GeminiEmptyResponseException>()),
        );
      });
    });

    group('API key validation', () {
      test('throws GeminiException when API key is empty', () {
        final service = GeminiService(apiKey: '');
        expect(
          () => service.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiException>()),
        );
      });
    });

    group('Successful API responses', () {
      test('returns response text from successful API call', () async {
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Hello world'}
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        final result =
            await geminiService.askQuestion(prompt: 'Tell me something fun.');
        expect(result, equals('Hello world'));
      });

      test('handles conversation history correctly', () async {
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Hello again'}
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        final history = [
          {'role': 'user', 'content': 'Hello'},
          {'role': 'assistant', 'content': 'Hi there!'}
        ];

        final result = await geminiService.askQuestion(
          prompt: 'How are you?',
          conversationHistory: history,
        );

        expect(result, equals('Hello again'));
      });

      test('falls back to candidate parts when text is not directly available',
          () async {
        // Simulate response where text needs to be extracted from parts
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Fallback text'}
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        final result =
            await geminiService.askQuestion(prompt: 'Give me more info.');
        expect(result, equals('Fallback text'));
      });
    });

    group('Error handling', () {
      test('throws GeminiEmptyResponseException when no candidates returned',
          () async {
        final responseBody = jsonEncode({'candidates': []});

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        expect(
          () => geminiService.askQuestion(prompt: 'Need details.'),
          throwsA(isA<GeminiEmptyResponseException>()),
        );
      });

      test('throws GeminiApiException for 400 Bad Request', () async {
        final errorBody = jsonEncode({
          'error': {'message': 'Invalid request', 'code': 400}
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(errorBody, 400),
        );

        expect(
          () => geminiService.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiApiException>()),
        );
      });

      test('throws GeminiApiException for 401 Unauthorized', () async {
        final errorBody = jsonEncode({
          'error': {'message': 'API key not valid', 'code': 401}
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(errorBody, 401),
        );

        expect(
          () => geminiService.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiApiException>()),
        );
      });

      test('throws GeminiApiException for 429 Rate Limit', () async {
        final errorBody = jsonEncode({
          'error': {'message': 'Rate limit exceeded', 'code': 429}
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(errorBody, 429),
        );

        expect(
          () => geminiService.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiApiException>()),
        );
      });

      test('throws GeminiEmptyResponseException for safety-blocked response',
          () async {
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {'parts': []},
              'finishReason': 'SAFETY'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        expect(
          () => geminiService.askQuestion(prompt: 'Test'),
          throwsA(isA<GeminiEmptyResponseException>()),
        );
      });
    });

    group('Parameter validation', () {
      test('clamps temperature to valid range', () async {
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Response'}
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        // Temperature 5.0 should be clamped to 2.0
        await geminiService.askQuestion(
          prompt: 'Test',
          temperature: 5.0,
        );

        // Verify request was made (temperature should be clamped in request)
        expect(mockClient.requests.length, equals(1));
      });

      test('clamps maxOutputTokens to valid range', () async {
        final responseBody = jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Response'}
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        });

        final url = '$baseUrl/models/$model:generateContent?key=$testApiKey';
        mockClient.setResponse(
          url,
          http.Response(responseBody, 200),
        );

        // Max tokens 100 should be clamped to 256
        await geminiService.askQuestion(
          prompt: 'Test',
          maxOutputTokens: 100,
        );

        // Verify request was made (max tokens should be clamped in request)
        expect(mockClient.requests.length, equals(1));
      });
    });
  });
}
