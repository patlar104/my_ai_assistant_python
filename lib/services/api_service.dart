import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversation.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://127.0.0.1:5000';
  
  String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? defaultBaseUrl;
  }

  Future<AskResponse> askQuestion({
    required String prompt,
    String? conversationId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'conversation_id': conversationId,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AskResponse(
          response: data['response'] as String,
          conversationId: data['conversation_id'] as String?,
        );
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] as String? ?? 
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        throw ApiException(errorMessage);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<List<ConversationMetadata>> listConversations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/conversations'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final conversations = data['conversations'] as List<dynamic>;
        return conversations
            .map((conv) => ConversationMetadata.fromJson(conv as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$conversationId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Conversation.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ApiException('Conversation not found');
      } else {
        throw ApiException('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<String> createConversation() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/new'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['conversation_id'] as String;
      } else {
        throw ApiException('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$conversationId'),
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to delete conversation: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }
}

class AskResponse {
  final String response;
  final String? conversationId;

  AskResponse({
    required this.response,
    this.conversationId,
  });
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}
