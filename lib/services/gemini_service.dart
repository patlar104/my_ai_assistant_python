import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'exceptions.dart';

class GeminiService {
  static const String defaultModel = 'gemini-2.5-flash';
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final http.Client _httpClient;

  GeminiService({
    String? apiKey,
    http.Client? httpClient,
  })  : apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        _httpClient = httpClient ?? http.Client();

  // Keywords for prompt analysis
  static const Set<String> researchKeywords = {
    'research',
    'study',
    'analyze',
    'analysis',
    'report',
    'paper',
    'whitepaper',
    'thesis',
    'investigate',
    'explain',
    'context',
    'academic',
  };

  static const Set<String> sensitiveKeywords = {
    'election',
    'policy',
    'politic',
    'government',
    'law',
    'current event',
    'geopolit',
    'conflict',
    'war',
    'protest',
    'legislation',
    'campaign',
  };

  static const Set<String> timeSensitiveKeywords = {
    'today',
    'tonight',
    'current',
    'latest',
    'recent',
    'now',
    'deadline',
    'forecast',
    'schedule',
    'timeline',
    'this week',
    'this month',
    'breaking',
  };

  static const String baseSystemPromptTemplate =
      'You are My AI Assistant, a neutral research aide. '
      'Offer balanced, factual summaries, cite reputable public sources when '
      'possible, and clearly label speculation. Decline policy-violating requests '
      'with a courteous explanation. Always assume the current date is {current_date} '
      'and the current time is {current_time} when answering time-sensitive questions.';

  /// Analyze prompt to determine context flags
  Map<String, bool> _analyzePrompt(String prompt) {
    final lowered = prompt.toLowerCase();
    return {
      'isSensitive':
          sensitiveKeywords.any((keyword) => lowered.contains(keyword)),
      'isResearch':
          researchKeywords.any((keyword) => lowered.contains(keyword)),
      'isTimeSensitive':
          timeSensitiveKeywords.any((keyword) => lowered.contains(keyword)),
    };
  }

  /// Get current date and time strings
  Map<String, String> _currentDateTimeStrings() {
    final now = DateTime.now();
    return {
      'currentDate':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'currentTime':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
    };
  }

  /// Ask Gemini a question with optional conversation history
  Future<String> askQuestion({
    required String prompt,
    List<Map<String, String>>? conversationHistory,
    String model = defaultModel,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
    Duration? timeout,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('GEMINI_API_KEY is not set. Check your .env file.');
    }

    if (prompt.trim().isEmpty) {
      throw GeminiEmptyResponseException(
          'Prompt is empty. Please enter a question or request.');
    }

    // Build system context
    final analysis = _analyzePrompt(prompt);
    final dateTime = _currentDateTimeStrings();

    String systemInstruction = baseSystemPromptTemplate
        .replaceAll('{current_date}', dateTime['currentDate']!)
        .replaceAll('{current_time}', dateTime['currentTime']!);

    // Add contextual instructions
    final List<String> contextInstructions = [];

    if (analysis['isSensitive'] == true && analysis['isResearch'] == true) {
      contextInstructions.add(
          'Context: The user is examining a sensitive or political subject '
          'purely for neutral/academic research.');
    } else if (analysis['isSensitive'] == true) {
      contextInstructions.add(
          'Context: This touches on sensitive civic topics. Provide factual, '
          'balanced analysis and avoid persuasion.');
    } else if (analysis['isResearch'] == true) {
      contextInstructions.add(
          'Context: Treat the request as a scholarly or technical research task.');
    }

    if (analysis['isTimeSensitive'] == true) {
      contextInstructions.add(
          'Context: The user stressed timeliness. Use the stated current date '
          "${dateTime['currentDate']} and time ${dateTime['currentTime']} when framing your answer.");
    }

    final extraContext = dotenv.env['ASSISTANT_EXTRA_CONTEXT']?.trim();
    if (extraContext != null && extraContext.isNotEmpty) {
      contextInstructions.add(extraContext);
    }

    // Build contents array for Gemini API
    final List<Map<String, dynamic>> contents = [];

    // Add system instruction as first message
    String systemMessage = systemInstruction;
    if (contextInstructions.isNotEmpty) {
      systemMessage += '\n\n${contextInstructions.join('\n')}';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': systemMessage}
      ]
    });

    contents.add({
      'role': 'model',
      'parts': [
        {'text': "Understood. I'll follow these guidelines."}
      ]
    });

    // Add conversation history if provided
    if (conversationHistory != null) {
      for (final msg in conversationHistory) {
        final role = msg['role'] ?? 'user';
        final content = msg['content'] ?? '';

        if (content.isEmpty) continue;

        // Map "assistant" to "model" for Gemini API
        String apiRole;
        if (role == 'assistant') {
          apiRole = 'model';
        } else if (role == 'user' || role == 'model') {
          apiRole = role;
        } else {
          continue; // Skip invalid roles
        }

        contents.add({
          'role': apiRole,
          'parts': [
            {'text': content}
          ]
        });
      }
    }

    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt.trim()}
      ]
    });

    // Validate and clamp parameters
    final clampedTemperature = temperature.clamp(0.0, 2.0);
    final clampedMaxTokens = maxOutputTokens.clamp(256, 8192);

    // Build request payload
    final requestBody = {
      'contents': contents,
      'generationConfig': {
        'temperature': clampedTemperature,
        'maxOutputTokens': clampedMaxTokens,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_CIVIC_INTEGRITY',
          'threshold': 'BLOCK_ONLY_HIGH',
        }
      ],
    };

    try {
      final url =
          Uri.parse('$baseUrl/models/$model:generateContent?key=$apiKey');

      // Add timeout handling
      final requestTimeout = timeout ?? const Duration(seconds: 30);

      final response = await _httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(requestTimeout);

      // Handle HTTP errors
      if (response.statusCode != 200) {
        String errorMessage =
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        String? errorCode;

        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
          final error = errorData?['error'] as Map<String, dynamic>?;
          errorMessage = error?['message'] as String? ?? errorMessage;
          errorCode = error?['code']?.toString();
        } catch (_) {
          // If JSON parsing fails, use default error message
        }

        // Provide user-friendly error messages based on status code
        switch (response.statusCode) {
          case 400:
            errorMessage = 'Invalid request: $errorMessage';
            break;
          case 401:
            errorMessage = 'Authentication failed. Please check your API key.';
            break;
          case 403:
            errorMessage =
                'Access forbidden. Please check your API key permissions.';
            break;
          case 429:
            errorMessage = 'Rate limit exceeded. Please try again later.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage = 'Server error. Please try again later.';
            break;
        }

        throw GeminiApiException(
          errorMessage,
          response.statusCode,
          code: errorCode,
        );
      }

      // Parse response JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw GeminiApiException(
          'Invalid response format from Gemini API',
          response.statusCode,
          originalError: e,
        );
      }

      // Robustly extract text: prefer direct text field, otherwise fall back to candidate parts
      // This matches Python's implementation
      String? text;

      // First, try to get text directly from response (if available in future API versions)
      // Currently Gemini REST API doesn't have a top-level text field, but we check candidates

      // Extract text from candidates (matching Python's fallback logic)
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiEmptyResponseException(
          'The assistant didn\'t return any text. The response may have been blocked by safety filters. Try rephrasing your question.',
        );
      }

      // Try to extract text from first candidate
      final candidate = candidates[0] as Map<String, dynamic>?;
      if (candidate != null) {
        final content = candidate['content'] as Map<String, dynamic>?;
        if (content != null) {
          final parts = content['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final textParts = <String>[];
            for (final part in parts) {
              final partMap = part as Map<String, dynamic>;
              final partText = partMap['text'] as String?;
              if (partText != null && partText.isNotEmpty) {
                textParts.add(partText);
              }
            }
            if (textParts.isNotEmpty) {
              text = textParts.join('\n').trim();
            }
          }
        }

        // Check for finish reason (safety blocking, etc.)
        final finishReason = candidate['finishReason'] as String?;
        if (finishReason != null && finishReason != 'STOP' && text == null) {
          String reasonMessage = 'Response was blocked';
          switch (finishReason) {
            case 'SAFETY':
              reasonMessage =
                  'Response was blocked by safety filters. Try rephrasing your question.';
              break;
            case 'MAX_TOKENS':
              reasonMessage = 'Response was truncated due to token limit.';
              break;
            case 'RECITATION':
              reasonMessage =
                  'Response was blocked due to recitation concerns.';
              break;
          }
          throw GeminiEmptyResponseException(reasonMessage);
        }
      }

      if (text == null || text.isEmpty) {
        throw GeminiEmptyResponseException(
          'The assistant didn\'t return any text. Try again or rephrase your question.',
        );
      }

      if (kDebugMode) {
        debugPrint(
            'GeminiService: Successfully received response (${text.length} chars)');
      }

      return text;
    } on GeminiException {
      rethrow;
    } on http.ClientException catch (e) {
      throw GeminiNetworkException(
        'Network error: Unable to connect to Gemini API. Check your internet connection.',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw GeminiNetworkException(
        'Request timeout: The API request took too long. Please try again.',
        originalError: e,
      );
    } on FormatException catch (e) {
      throw GeminiApiException(
        'Invalid response format from Gemini API',
        200,
        originalError: e,
      );
    } catch (e) {
      throw GeminiException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
