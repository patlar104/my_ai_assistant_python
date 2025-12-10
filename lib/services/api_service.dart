import 'gemini_service.dart';
import '../models/conversation.dart';

class ApiService {
  final GeminiService _geminiService;
  
  ApiService({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();
  
  Future<AskResponse> askQuestion({
    required String prompt,
    String? conversationId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      // Convert conversation history if available
      List<Map<String, String>>? conversationHistory;
      if (conversationId != null) {
        // Note: Conversation history will be loaded by ConversationService
        // and passed separately. For now, we'll handle it in ChatView.
        conversationHistory = null; // Will be provided by caller
      }
      
      final response = await _geminiService.askQuestion(
        prompt: prompt,
        conversationHistory: conversationHistory,
        temperature: temperature,
        maxOutputTokens: maxTokens,
      );
      
      return AskResponse(
        response: response,
        conversationId: conversationId,
      );
    } catch (e) {
      if (e is GeminiException) {
        throw ApiException(e.message);
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  /// Ask question with conversation history
  Future<AskResponse> askQuestionWithHistory({
    required String prompt,
    required List<Map<String, String>> conversationHistory,
    String? conversationId,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final response = await _geminiService.askQuestion(
        prompt: prompt,
        conversationHistory: conversationHistory,
        temperature: temperature,
        maxOutputTokens: maxTokens,
      );
      
      return AskResponse(
        response: response,
        conversationId: conversationId,
      );
    } catch (e) {
      if (e is GeminiException) {
        throw ApiException(e.message);
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }
  
  // Legacy methods kept for compatibility but not used
  Future<List<ConversationMetadata>> listConversations() async {
    throw ApiException('Use ConversationService.listConversations() instead');
  }
  
  Future<Conversation> getConversation(String conversationId) async {
    throw ApiException('Use ConversationService.loadConversation() instead');
  }
  
  Future<String> createConversation() async {
    throw ApiException('Use ConversationService.createNewConversation() instead');
  }
  
  Future<void> deleteConversation(String conversationId) async {
    throw ApiException('Use ConversationService.deleteConversation() instead');
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
