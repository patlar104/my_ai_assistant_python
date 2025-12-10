import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import 'local_conversation_storage.dart';

class ConversationService extends ChangeNotifier {
  final LocalConversationStorage _storage;
  
  List<ConversationMetadata> _conversations = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;

  ConversationService({
    LocalConversationStorage? storage,
  })  : _storage = storage ?? LocalConversationStorage();

  List<ConversationMetadata> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _setLoading(true);
    _error = null;
    try {
      _conversations = await _storage.listConversations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<String> createNewConversation() async {
    _setLoading(true);
    _error = null;
    try {
      final conversationId = await _storage.createConversation();
      _currentConversationId = conversationId;
      _currentConversation = null;
      await loadConversations();
      notifyListeners();
      return conversationId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConversation(String conversationId) async {
    _setLoading(true);
    _error = null;
    try {
      final conversation = await _storage.loadConversation(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }
      _currentConversation = conversation;
      _currentConversationId = conversationId;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    _setLoading(true);
    _error = null;
    try {
      final success = await _storage.deleteConversation(conversationId);
      if (!success) {
        throw Exception('Conversation not found');
      }
      
      if (_currentConversationId == conversationId) {
        _currentConversationId = null;
        _currentConversation = null;
      }
      
      await loadConversations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAllConversations() async {
    _setLoading(true);
    _error = null;
    try {
      for (final conv in _conversations) {
        await _storage.deleteConversation(conv.id);
      }
      _currentConversationId = null;
      _currentConversation = null;
      await loadConversations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Add a message to the current conversation
  Future<void> addMessage(String role, String content) async {
    if (_currentConversationId == null) {
      throw Exception('No active conversation');
    }
    
    try {
      final updated = await _storage.addMessage(
        _currentConversationId!,
        role,
        content,
      );
      
      if (updated != null) {
        _currentConversation = updated;
        await loadConversations(); // Update metadata
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Get conversation history in format for Gemini API
  List<Map<String, String>> getConversationHistory() {
    if (_currentConversation == null) {
      return [];
    }
    
    return _currentConversation!.messages
        .map((msg) => {
              'role': msg.role,
              'content': msg.content,
            })
        .toList();
  }

  void setCurrentConversationId(String? conversationId) {
    _currentConversationId = conversationId;
    if (conversationId == null) {
      _currentConversation = null;
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
