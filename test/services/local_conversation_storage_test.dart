import 'package:flutter_test/flutter_test.dart';
import 'package:my_ai_assistant/services/local_conversation_storage.dart';
import 'package:my_ai_assistant/models/conversation.dart';
import 'dart:io';

void main() {
  late LocalConversationStorage storage;
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for each test
    tempDir = await Directory.systemTemp.createTemp('conversation_test_');
    final conversationsDir = Directory('${tempDir.path}/conversations');
    await conversationsDir.create(recursive: true);
    
    // Create storage with directory override for testing
    storage = LocalConversationStorage(
      getDirectoryOverride: () async => conversationsDir,
    );
  });

  tearDown(() async {
    // Clean up temp directory
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  });

  group('LocalConversationStorage', () {
    group('createConversation', () {
      test('creates a new conversation and returns ID', () async {
        final conversationId = await storage.createConversation();

        expect(conversationId, isNotNull);
        expect(conversationId.length, greaterThan(0));
        expect(conversationId, isA<String>());
      });

      test('creates unique conversation IDs', () async {
        final id1 = await storage.createConversation();
        final id2 = await storage.createConversation();

        expect(id1, isNot(equals(id2)));
      });

      test('creates conversation file on disk', () async {
        final conversationId = await storage.createConversation();
        final conversation = await storage.loadConversation(conversationId);

        expect(conversation, isNotNull);
        expect(conversation?.id, equals(conversationId));
        expect(conversation?.messages, isEmpty);
      });
    });

    group('saveConversation and loadConversation', () {
      test('saves and loads a conversation correctly', () async {
        final conversationId = await storage.createConversation();
        
        final conversation = Conversation(
          id: conversationId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messages: [
            Message(
              role: 'user',
              content: 'Hello',
              timestamp: DateTime.now(),
            ),
            Message(
              role: 'assistant',
              content: 'Hi!',
              timestamp: DateTime.now(),
            ),
          ],
        );

        await storage.updateConversation(conversation);
        final loaded = await storage.loadConversation(conversationId);

        expect(loaded, isNotNull);
        expect(loaded?.id, equals(conversationId));
        expect(loaded?.messages.length, equals(2));
        expect(loaded?.messages[0].role, equals('user'));
        expect(loaded?.messages[0].content, equals('Hello'));
        expect(loaded?.messages[1].role, equals('assistant'));
        expect(loaded?.messages[1].content, equals('Hi!'));
      });

      test('returns null for nonexistent conversation', () async {
        final loaded = await storage.loadConversation('nonexistent-id');

        expect(loaded, isNull);
      });

      test('updates updated_at timestamp on save', () async {
        final conversationId = await storage.createConversation();
        final conversation1 = await storage.loadConversation(conversationId);
        expect(conversation1, isNotNull);

        // Wait a bit to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        final updated = conversation1!.copyWith(
          messages: [
            ...conversation1.messages,
            Message(
              role: 'user',
              content: 'New message',
              timestamp: DateTime.now(),
            ),
          ],
        );

        await storage.updateConversation(updated);
        final conversation2 = await storage.loadConversation(conversationId);

        expect(conversation2, isNotNull);
        expect(
          conversation2!.updatedAt.isAfter(conversation1.updatedAt),
          isTrue,
        );
      });
    });

    group('listConversations', () {
      test('returns empty list when no conversations exist', () async {
        final conversations = await storage.listConversations();

        expect(conversations, isEmpty);
      });

      test('lists all conversations with metadata', () async {
        final id1 = await storage.createConversation();
        final id2 = await storage.createConversation();

        // Add messages to one conversation
        await storage.addMessage(id1, 'user', 'Test message');

        final conversations = await storage.listConversations();

        expect(conversations.length, equals(2));
        expect(conversations.any((c) => c.id == id1), isTrue);
        expect(conversations.any((c) => c.id == id2), isTrue);
        
        // Check metadata
        for (final conv in conversations) {
          expect(conv.id, isNotEmpty);
          expect(conv.createdAt, isNotNull);
          expect(conv.updatedAt, isNotNull);
          expect(conv.messageCount, greaterThanOrEqualTo(0));
        }

        // Find the conversation with the message
        final convWithMessage = conversations.firstWhere((c) => c.id == id1);
        expect(convWithMessage.messageCount, equals(1));
      });

      test('sorts conversations by updated_at, most recent first', () async {
        final id1 = await storage.createConversation();
        await Future.delayed(const Duration(milliseconds: 10));
        await storage.createConversation();
        await Future.delayed(const Duration(milliseconds: 10));
        await storage.createConversation();

        // Update the first conversation to make it most recent
        await storage.addMessage(id1, 'user', 'Update');

        final conversations = await storage.listConversations();

        expect(conversations.length, equals(3));
        expect(conversations[0].id, equals(id1)); // Most recently updated
      });
    });

    group('deleteConversation', () {
      test('deletes an existing conversation', () async {
        final conversationId = await storage.createConversation();

        // Verify it exists
        final before = await storage.loadConversation(conversationId);
        expect(before, isNotNull);

        // Delete it
        final success = await storage.deleteConversation(conversationId);
        expect(success, isTrue);

        // Verify it's gone
        final after = await storage.loadConversation(conversationId);
        expect(after, isNull);
      });

      test('returns false for nonexistent conversation', () async {
        final success = await storage.deleteConversation('nonexistent-id');

        expect(success, isFalse);
      });
    });

    group('addMessage', () {
      test('adds a message to an existing conversation', () async {
        final conversationId = await storage.createConversation();

        final updated = await storage.addMessage(
          conversationId,
          'user',
          'Hello',
        );

        expect(updated, isNotNull);
        expect(updated?.messages.length, equals(1));
        expect(updated?.messages[0].role, equals('user'));
        expect(updated?.messages[0].content, equals('Hello'));
      });

      test('adds multiple messages in sequence', () async {
        final conversationId = await storage.createConversation();

        await storage.addMessage(conversationId, 'user', 'Hello');
        final updated = await storage.addMessage(
          conversationId,
          'assistant',
          'Hi there!',
        );

        expect(updated, isNotNull);
        expect(updated?.messages.length, equals(2));
        expect(updated?.messages[0].role, equals('user'));
        expect(updated?.messages[1].role, equals('assistant'));
      });

      test('returns null for nonexistent conversation', () async {
        final result = await storage.addMessage(
          'nonexistent-id',
          'user',
          'Hello',
        );

        expect(result, isNull);
      });

      test('updates conversation timestamp when adding message', () async {
        final conversationId = await storage.createConversation();
        final conversation1 = await storage.loadConversation(conversationId);
        expect(conversation1, isNotNull);

        await Future.delayed(const Duration(milliseconds: 10));

        await storage.addMessage(conversationId, 'user', 'New message');
        final conversation2 = await storage.loadConversation(conversationId);

        expect(conversation2, isNotNull);
        expect(
          conversation2!.updatedAt.isAfter(conversation1!.updatedAt),
          isTrue,
        );
      });
    });

    group('Error handling', () {
      test('handles corrupted JSON files gracefully', () async {
        // Create a conversation first to get a valid ID
        final conversationId = await storage.createConversation();
        
        // Get the conversations directory from storage
        final conversationsDir = Directory('${tempDir.path}/conversations');
        final file = File('${conversationsDir.path}/$conversationId.json');

        // Verify file exists, then corrupt it
        expect(await file.exists(), isTrue);
        await file.writeAsString('invalid json{');

        // listConversations should skip corrupted files
        final conversations = await storage.listConversations();
        // The corrupted file should be skipped, so we should have 0 conversations
        expect(conversations.length, lessThanOrEqualTo(1));
      });
    });
  });
}

