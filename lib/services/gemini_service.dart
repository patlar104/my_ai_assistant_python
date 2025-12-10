import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String defaultModel = 'gemini-2.5-flash';
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  final String apiKey;
  
  GeminiService({String? apiKey}) 
      : apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '';
  
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
      'isSensitive': sensitiveKeywords.any((keyword) => lowered.contains(keyword)),
      'isResearch': researchKeywords.any((keyword) => lowered.contains(keyword)),
      'isTimeSensitive': timeSensitiveKeywords.any((keyword) => lowered.contains(keyword)),
    };
  }
  
  /// Get current date and time strings
  Map<String, String> _currentDateTimeStrings() {
    final now = DateTime.now();
    return {
      'currentDate': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'currentTime': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
    };
  }
  
  /// Ask Gemini a question with optional conversation history
  Future<String> askQuestion({
    required String prompt,
    List<Map<String, String>>? conversationHistory,
    String model = defaultModel,
    double temperature = 0.7,
    int maxOutputTokens = 2048,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('GEMINI_API_KEY is not set. Check your .env file.');
    }
    
    if (prompt.trim().isEmpty) {
      throw GeminiException('Prompt is empty. Please enter a question or request.');
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
        'purely for neutral/academic research.'
      );
    } else if (analysis['isSensitive'] == true) {
      contextInstructions.add(
        'Context: This touches on sensitive civic topics. Provide factual, '
        'balanced analysis and avoid persuasion.'
      );
    } else if (analysis['isResearch'] == true) {
      contextInstructions.add(
        'Context: Treat the request as a scholarly or technical research task.'
      );
    }
    
    if (analysis['isTimeSensitive'] == true) {
      contextInstructions.add(
        'Context: The user stressed timeliness. Use the stated current date '
        "${dateTime['currentDate']} and time ${dateTime['currentTime']} when framing your answer."
      );
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
      'parts': [{'text': systemMessage}]
    });
    
    contents.add({
      'role': 'model',
      'parts': [{'text': "Understood. I'll follow these guidelines."}]
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
          'parts': [{'text': content}]
        });
      }
    }
    
    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt.trim()}]
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
      final url = Uri.parse('$baseUrl/models/$model:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?['message'] as String? ?? 
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        throw GeminiException('Gemini API error: $errorMessage');
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Extract text from response
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiException('The assistant didn\'t return any text. Try again.');
      }
      
      final candidate = candidates[0] as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      
      if (parts == null || parts.isEmpty) {
        throw GeminiException('The assistant didn\'t return any text. Try again.');
      }
      
      final textParts = <String>[];
      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;
        final text = partMap['text'] as String?;
        if (text != null && text.isNotEmpty) {
          textParts.add(text);
        }
      }
      
      if (textParts.isEmpty) {
        throw GeminiException('The assistant didn\'t return any text. Try again.');
      }
      
      return textParts.join('\n').trim();
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('Something went wrong talking to the AI backend. ${e.toString()}');
    }
  }
}

class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);
  
  @override
  String toString() => message;
}

