import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import 'exceptions.dart';

class LocalConversationStorage {
  static const _uuid = Uuid();
  Directory? _conversationsDir;
  final Future<Directory> Function()? _getDirectoryOverride;

  LocalConversationStorage({Future<Directory> Function()? getDirectoryOverride})
      : _getDirectoryOverride = getDirectoryOverride;

  Future<Directory> _getConversationsDirectory() async {
    if (_conversationsDir != null) {
      return _conversationsDir!;
    }

    if (_getDirectoryOverride != null) {
      _conversationsDir = await _getDirectoryOverride!();
      if (!await _conversationsDir!.exists()) {
        await _conversationsDir!.create(recursive: true);
      }
      return _conversationsDir!;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    _conversationsDir = Directory('${appDocDir.path}/conversations');

    if (!await _conversationsDir!.exists()) {
      await _conversationsDir!.create(recursive: true);
    }

    return _conversationsDir!;
  }

  /// Create a new conversation and return its ID
  Future<String> createConversation() async {
    final conversationId = _uuid.v4();
    final conversation = {
      'id': conversationId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'messages': <Map<String, dynamic>>[],
    };

    await saveConversation(conversation);
    return conversationId;
  }

  /// Save a conversation to disk
  Future<void> saveConversation(Map<String, dynamic> conversation) async {
    final conversationId = conversation['id'] as String;
    final updatedConversation = Map<String, dynamic>.from(conversation);
    updatedConversation['updated_at'] = DateTime.now().toIso8601String();

    final dir = await _getConversationsDirectory();
    final file = File('${dir.path}/$conversationId.json');

    try {
      await file.writeAsString(
        jsonEncode(updatedConversation),
        encoding: utf8,
      );
    } on FileSystemException catch (e) {
      throw ConversationPermissionException(
        'Failed to save conversation: Permission denied or disk full',
        conversationId: conversationId,
        originalError: e,
      );
    } on FormatException catch (e) {
      throw ConversationStorageException(
        'Failed to encode conversation data',
        conversationId: conversationId,
        originalError: e,
      );
    } catch (e) {
      throw ConversationStorageException(
        'Failed to save conversation',
        conversationId: conversationId,
        originalError: e,
      );
    }
  }

  /// Update an existing conversation
  Future<void> updateConversation(Conversation conversation) async {
    await saveConversation(conversation.toJson());
  }

  /// Load a conversation by ID
  Future<Conversation?> loadConversation(String conversationId) async {
    final dir = await _getConversationsDirectory();
    final file = File('${dir.path}/$conversationId.json');

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString(encoding: utf8);
      Map<String, dynamic> data;
      try {
        data = jsonDecode(content) as Map<String, dynamic>;
      } on FormatException catch (e) {
        throw ConversationCorruptedException(
          conversationId,
          originalError: e,
        );
      }

      try {
        return Conversation.fromJson(data);
      } catch (e) {
        throw ConversationCorruptedException(
          conversationId,
          originalError: e,
        );
      }
    } on FileSystemException catch (e) {
      throw ConversationPermissionException(
        'Failed to read conversation file: Permission denied',
        conversationId: conversationId,
        originalError: e,
      );
    } on ConversationCorruptedException {
      rethrow;
    } catch (e) {
      throw ConversationStorageException(
        'Failed to load conversation',
        conversationId: conversationId,
        originalError: e,
      );
    }
  }

  /// List all conversations with metadata
  Future<List<ConversationMetadata>> listConversations() async {
    final conversations = <ConversationMetadata>[];

    final dir = await _getConversationsDirectory();
    if (!await dir.exists()) {
      return conversations;
    }

    try {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString(encoding: utf8);
            final data = jsonDecode(content) as Map<String, dynamic>;

            // Count only user messages (not assistant responses)
            final messages = (data['messages'] as List<dynamic>?) ?? [];
            final userMessageCount = messages
                .where((msg) => (msg as Map<String, dynamic>)['role'] == 'user')
                .length;

            conversations.add(ConversationMetadata.fromJson({
              'id': data['id'] as String,
              'created_at': data['created_at'] as String,
              'updated_at': data['updated_at'] as String,
              'message_count': userMessageCount,
            }));
          } catch (e) {
            // Skip corrupted files
            continue;
          }
        }
      }

      // Sort by updated_at, most recent first
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } on FileSystemException catch (e) {
      throw ConversationPermissionException(
        'Failed to list conversations: Permission denied',
        originalError: e,
      );
    } catch (e) {
      throw ConversationStorageException(
        'Failed to list conversations',
        originalError: e,
      );
    }
  }

  /// Delete a conversation by ID
  Future<bool> deleteConversation(String conversationId) async {
    final dir = await _getConversationsDirectory();
    final file = File('${dir.path}/$conversationId.json');

    if (!await file.exists()) {
      return false;
    }

    try {
      await file.delete();
      return true;
    } on FileSystemException catch (e) {
      throw ConversationPermissionException(
        'Failed to delete conversation: Permission denied',
        conversationId: conversationId,
        originalError: e,
      );
    } catch (e) {
      throw ConversationStorageException(
        'Failed to delete conversation',
        conversationId: conversationId,
        originalError: e,
      );
    }
  }

  /// Add a message to a conversation
  Future<Conversation?> addMessage(
    String conversationId,
    String role,
    String content,
  ) async {
    final conversation = await loadConversation(conversationId);
    if (conversation == null) {
      return null;
    }

    final messages = conversation.messages.toList();
    messages.add(Message(
      role: role,
      content: content,
      timestamp: DateTime.now(),
    ));

    final updatedConversation = conversation.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    await saveConversation(updatedConversation.toJson());
    return updatedConversation;
  }
}
