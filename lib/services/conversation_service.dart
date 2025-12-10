import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import 'api_service.dart';

class ConversationService extends ChangeNotifier {
  final ApiService _apiService;
  
  List<ConversationMetadata> _conversations = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;

  ConversationService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<ConversationMetadata> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  String? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _setLoading(true);
    _error = null;
    try {
      _conversations = await _apiService.listConversations();
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
      final conversationId = await _apiService.createConversation();
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
      final conversation = await _apiService.getConversation(conversationId);
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
      await _apiService.deleteConversation(conversationId);
      
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
        await _apiService.deleteConversation(conv.id);
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
