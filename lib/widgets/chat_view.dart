import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/local_conversation_storage.dart';
import '../models/conversation.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String? _lastPrompt;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final prompt = _textController.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _lastPrompt = prompt;
    });

    final conversationService = context.read<ConversationService>();
    final apiService = context.read<ApiService>();

    // Update current conversation or create new one
    String? conversationId = conversationService.currentConversationId;
    if (conversationId == null) {
      try {
        conversationId = await conversationService.createNewConversation();
      } catch (e) {
        if (mounted) {
          _showError('Failed to create conversation: $e');
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // Load conversation to get history if not already loaded
    if (conversationService.currentConversation == null) {
      try {
        await conversationService.loadConversation(conversationId);
      } catch (e) {
        // Continue anyway
      }
    }

    _textController.clear();
    _focusNode.unfocus();

    try {
      // Add user message to conversation
      await conversationService.addMessage('user', prompt);

      // Get conversation history (last 20 messages)
      final allHistory = conversationService.getConversationHistory();
      final recentHistory = allHistory.length > 20
          ? allHistory.sublist(allHistory.length - 20)
          : allHistory;

      // Get settings
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();

      // Call API with conversation history
      final response = await apiService.askQuestionWithHistory(
        prompt: prompt,
        conversationHistory: recentHistory,
        conversationId: conversationId,
        temperature: settingsService.temperature,
        maxTokens: settingsService.maxTokens,
      );

      // Add assistant response to conversation
      await conversationService.addMessage('assistant', response.response);

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _regenerateLastResponse() async {
    if (_lastPrompt == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final conversationService = context.read<ConversationService>();
    final apiService = context.read<ApiService>();
    final conversationId = conversationService.currentConversationId;

    if (conversationId == null) {
      _showError('No conversation to regenerate');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Remove last assistant message from conversation if it exists
      final conversation = conversationService.currentConversation;
      if (conversation != null && conversation.messages.isNotEmpty) {
        final lastMessage = conversation.messages.last;
        if (lastMessage.role == 'assistant') {
          // Remove the last assistant message and save
          final updatedMessages = conversation.messages.sublist(
            0,
            conversation.messages.length - 1,
          );
          final updatedConversation = conversation.copyWith(
            messages: updatedMessages,
            updatedAt: DateTime.now(),
          );
          // Save the updated conversation
          final storage = LocalConversationStorage();
          await storage.updateConversation(updatedConversation);
          // Reload to get updated state
          await conversationService.loadConversation(conversationId);
        }
      }

      // Get conversation history (last 20 messages, excluding the last assistant message if we removed it)
      final allHistory = conversationService.getConversationHistory();
      final recentHistory = allHistory.length > 20
          ? allHistory.sublist(allHistory.length - 20)
          : allHistory;

      // Get settings
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();

      // Call API with same prompt
      final response = await apiService.askQuestionWithHistory(
        prompt: _lastPrompt!,
        conversationHistory: recentHistory,
        conversationId: conversationId,
        temperature: settingsService.temperature,
        maxTokens: settingsService.maxTokens,
      );

      // Add new assistant response
      await conversationService.addMessage('assistant', response.response);

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error regenerating: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationService>(
      builder: (context, conversationService, _) {
        final conversation = conversationService.currentConversation;
        final messages = conversation?.messages ?? [];

        // Show welcome message if no conversation
        final displayMessages = messages.isEmpty
            ? [
                Message(
                  role: 'assistant',
                  content:
                      "Hello! I'm here and ready to help. How can I assist you today?",
                  timestamp: DateTime.now(),
                )
              ]
            : messages;

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My AI Assistant',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    'Backed by Gemini 2.5 Flash. Ask anything related to research, code, or explanations.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: displayMessages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < displayMessages.length) {
                    final message = displayMessages[index];
                    return MessageBubble(
                      message: message,
                      onRegenerate: message.role == 'assistant' &&
                              index == displayMessages.length - 1 &&
                              !_isLoading
                          ? _regenerateLastResponse
                          : null,
                    );
                  } else {
                    return const TypingIndicator();
                  }
                },
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything… (Shift+Enter for newline)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
