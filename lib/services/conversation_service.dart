import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import 'local_conversation_storage.dart';
import 'exceptions.dart';
import '../utils/debug_logger.dart';

class ConversationService extends ChangeNotifier {
  final LocalConversationStorage _storage;

  List<ConversationMetadata> _conversations = [];
  Conversation? _currentConversation;
  String? _currentConversationId;
  bool _isLoading = false;
  String? _error;

  ConversationService({
    LocalConversationStorage? storage,
  }) : _storage = storage ?? LocalConversationStorage();

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
        throw ConversationNotFoundException(conversationId);
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
        throw ConversationNotFoundException(conversationId);
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
    // #region agent log
    try {
      final logFile = File(
          r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
      final logEntry =
          '{"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"conversation_service.dart:124","message":"addMessage called","data":{"role":"$role","contentLength":${content.length},"conversationId":"$_currentConversationId"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
      logFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (_) {}
    // #endregion

    if (_currentConversationId == null) {
      throw ConversationStorageException('No active conversation');
    }

    try {
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"conversation_service.dart:130","message":"Before storage.addMessage","data":{"contentLength":${content.length}},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion
      final updated = await _storage.addMessage(
        _currentConversationId!,
        role,
        content,
      );
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final updatedLength = updated?.messages.length ?? 0;
        final lastMessageLength = updated?.messages.isNotEmpty == true
            ? updated!.messages.last.content.length
            : 0;
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"conversation_service.dart:135","message":"After storage.addMessage","data":{"updated":${updated != null},"messageCount":$updatedLength,"lastMessageLength":$lastMessageLength},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion

      if (updated != null) {
        _currentConversation = updated;
        await loadConversations(); // Update metadata
        // #region agent log
        try {
          final logFile = File(
              r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
          final logEntry =
              '{"sessionId":"debug-session","runId":"run1","hypothesisId":"F","location":"conversation_service.dart:139","message":"Before notifyListeners","data":{"messageCount":${updated.messages.length}},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
          logFile.writeAsStringSync(logEntry, mode: FileMode.append);
        } catch (_) {}
        // #endregion
        notifyListeners();
        // #region agent log
        try {
          final logFile = File(
              r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
          final logEntry =
              '{"sessionId":"debug-session","runId":"run1","hypothesisId":"F","location":"conversation_service.dart:139","message":"After notifyListeners","data":{},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
          logFile.writeAsStringSync(logEntry, mode: FileMode.append);
        } catch (_) {}
        // #endregion
      } else {
        // #region agent log
        try {
          final logFile = File(
              r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
          final logEntry =
              '{"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"conversation_service.dart:141","message":"addMessage returned null","data":{},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
          logFile.writeAsStringSync(logEntry, mode: FileMode.append);
        } catch (_) {}
        // #endregion
      }
    } catch (e) {
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"conversation_service.dart:141","message":"addMessage exception","data":{"error":"${e.toString().replaceAll('"', '\\"')}"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion
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

    final history = _currentConversation!.messages
        .map((msg) => {
              'role': msg.role,
              'content': msg.content,
            })
        .toList();

    // #region agent log
    DebugLogger.logDataFlow(
      location: 'conversation_service.dart:219',
      operation: 'getConversationHistory_called',
      data: {
        'conversationId': _currentConversation!.id,
        'totalMessages': _currentConversation!.messages.length,
        'historyLength': history.length,
        'messageRoles': history.map((m) => m['role']).toList(),
        'messageContentLengths':
            history.map((m) => (m['content']?.length ?? 0)).toList(),
      },
    );
    // #endregion

    return history;
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
