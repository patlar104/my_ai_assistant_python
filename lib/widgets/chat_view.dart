import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/local_conversation_storage.dart';
import '../models/conversation.dart';
import '../utils/debug_logger.dart';
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

    // #region agent log
    DebugLogger.logUserInteraction(
      location: 'chat_view.dart:46',
      action: 'send_message_clicked',
      data: {
        'promptLength': prompt.length,
        'isEmpty': prompt.isEmpty,
        'isLoading': _isLoading,
      },
    );
    // #endregion

    if (prompt.isEmpty || _isLoading) {
      // #region agent log
      DebugLogger.logUserInteraction(
        location: 'chat_view.dart:46',
        action: 'send_message_blocked',
        data: {
          'reason': prompt.isEmpty ? 'empty_prompt' : 'already_loading',
        },
      );
      // #endregion
      return;
    }

    setState(() {
      _isLoading = true;
      _lastPrompt = prompt;
    });

    // #region agent log
    DebugLogger.logStateChange(
      location: 'chat_view.dart:50',
      stateName: 'isLoading',
      oldValue: false,
      newValue: true,
    );
    // #endregion

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
      // IMPORTANT: Exclude the last user message since we're sending it as the prompt to avoid duplication
      final allHistory = conversationService.getConversationHistory();
      List<Map<String, String>> recentHistory = allHistory.length > 20
          ? allHistory.sublist(allHistory.length - 20)
          : List.from(allHistory);

      // Remove the last user message from history if it matches the prompt (to avoid duplication)
      if (recentHistory.isNotEmpty) {
        final lastHistoryMessage = recentHistory.last;
        if (lastHistoryMessage['role'] == 'user' &&
            lastHistoryMessage['content'] == prompt) {
          recentHistory = recentHistory.sublist(0, recentHistory.length - 1);

          // #region agent log
          DebugLogger.logDataFlow(
            location: 'chat_view.dart:122',
            operation: 'removed_duplicate_prompt_from_history_new_message',
            data: {
              'historyLengthBefore': allHistory.length,
              'historyLengthAfter': recentHistory.length,
              'removedPromptLength': prompt.length,
            },
          );
          // #endregion
        }
      }

      // Get settings
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();

      // #region agent log
      DebugLogger.logDataFlow(
        location: 'chat_view.dart:132',
        operation: 'sending_new_message_to_api',
        data: {
          'promptLength': prompt.length,
          'historyLength': recentHistory.length,
          'historyMessageCounts': {
            'user': recentHistory.where((m) => m['role'] == 'user').length,
            'assistant':
                recentHistory.where((m) => m['role'] == 'assistant').length,
          },
          'totalHistoryChars': recentHistory.fold<int>(
              0, (sum, m) => sum + (m['content']?.length ?? 0)),
        },
      );
      // #endregion

      // Call API with conversation history
      final response = await apiService.askQuestionWithHistory(
        prompt: prompt,
        conversationHistory: recentHistory,
        conversationId: conversationId,
        temperature: settingsService.temperature,
        maxTokens: settingsService.maxTokens,
      );

      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final preview = response.response.length > 200
            ? '${response.response.substring(0, 100)}...${response.response.substring(response.response.length - 100)}'
            : response.response;
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"B","location":"chat_view.dart:104","message":"Response received in ChatView","data":{"length":${response.response.length},"preview":"${preview.replaceAll('"', '\\"').replaceAll('\n', '\\n')}","conversationId":"$conversationId"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion

      // Add assistant response to conversation
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"chat_view.dart:107","message":"Before addMessage call","data":{"contentLength":${response.response.length},"conversationId":"$conversationId"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion
      await conversationService.addMessage('assistant', response.response);
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"chat_view.dart:128","message":"After addMessage call","data":{"conversationId":"$conversationId"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final conversation = conversationService.currentConversation;
        final messageCount = conversation?.messages.length ?? 0;
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"chat_view.dart:139","message":"Before setState","data":{"messageCount":$messageCount,"isLoading":$_isLoading},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion
      setState(() {
        _isLoading = false;
      });
      // #region agent log
      try {
        final logFile = File(
            r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
        final conversation = conversationService.currentConversation;
        final messageCount = conversation?.messages.length ?? 0;
        final lastMessage = conversation?.messages.isNotEmpty == true
            ? conversation!.messages.last.content.length
            : 0;
        final logEntry =
            '{"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"chat_view.dart:141","message":"After setState","data":{"messageCount":$messageCount,"lastMessageLength":$lastMessage},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
        logFile.writeAsStringSync(logEntry, mode: FileMode.append);
      } catch (_) {}
      // #endregion

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // #region agent log
      DebugLogger.logError(
        location: 'chat_view.dart:114',
        error: 'Failed to send message',
        originalError: e,
        context: {
          'promptLength': prompt.length,
          'conversationId': conversationId,
        },
      );
      // #endregion

      _showError('Error: ${e.toString()}');
    }
  }

  Future<void> _regenerateLastResponse() async {
    final conversationService = context.read<ConversationService>();
    final conversation = conversationService.currentConversation;

    // #region agent log
    DebugLogger.logUserInteraction(
      location: 'chat_view.dart:225',
      action: 'regenerate_response_clicked',
      data: {
        'hasLastPrompt': _lastPrompt != null,
        'isLoading': _isLoading,
        'hasConversation': conversation != null,
        'messageCount': conversation?.messages.length ?? 0,
        'lastUserMessageIndex':
            conversation?.messages.lastIndexWhere((m) => m.role == 'user') ??
                -1,
      },
    );
    // #endregion

    // If _lastPrompt is null, try to extract it from conversation messages
    String? promptToUse = _lastPrompt;
    bool extractedFromConversation = false;
    if (promptToUse == null &&
        conversation != null &&
        conversation.messages.isNotEmpty) {
      // Find the last user message
      for (int i = conversation.messages.length - 1; i >= 0; i--) {
        if (conversation.messages[i].role == 'user') {
          promptToUse = conversation.messages[i].content;
          extractedFromConversation = true;

          // #region agent log
          DebugLogger.logDataFlow(
            location: 'chat_view.dart:237',
            operation: 'extracted_last_prompt_from_conversation',
            data: {
              'messageIndex': i,
              'promptLength': promptToUse.length,
            },
          );
          // #endregion
          break;
        }
      }
    }

    if (promptToUse == null || _isLoading) {
      // #region agent log
      DebugLogger.logUserInteraction(
        location: 'chat_view.dart:225',
        action: 'regenerate_blocked',
        data: {
          'reason':
              promptToUse == null ? 'no_last_prompt_found' : 'already_loading',
          'hadLastPrompt': _lastPrompt != null,
          'extractedFromConversation':
              promptToUse != null && _lastPrompt == null,
        },
      );
      // #endregion
      if (promptToUse == null) {
        _showError('No previous message to regenerate');
      }
      return;
    }

    setState(() {
      _isLoading = true;
      // Update _lastPrompt if we extracted it from conversation
      if (_lastPrompt == null && promptToUse != null) {
        _lastPrompt = promptToUse;
      }
    });

    // #region agent log
    DebugLogger.logStateChange(
      location: 'chat_view.dart:250',
      stateName: 'isLoading',
      oldValue: false,
      newValue: true,
      additionalData: {
        'promptSource': _lastPrompt != null ? 'memory' : 'conversation',
        'promptLength': promptToUse.length,
      },
    );
    // #endregion

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
      // IMPORTANT: Exclude the last user message if we extracted it as promptToUse to avoid duplication
      final allHistory = conversationService.getConversationHistory();
      List<Map<String, String>> recentHistory = allHistory.length > 20
          ? allHistory.sublist(allHistory.length - 20)
          : List.from(allHistory);

      // If we extracted the prompt from conversation, remove it from history to avoid duplication
      if (extractedFromConversation && recentHistory.isNotEmpty) {
        final lastHistoryMessage = recentHistory.last;
        if (lastHistoryMessage['role'] == 'user' &&
            lastHistoryMessage['content'] == promptToUse) {
          recentHistory = recentHistory.sublist(0, recentHistory.length - 1);

          // #region agent log
          DebugLogger.logDataFlow(
            location: 'chat_view.dart:350',
            operation: 'removed_duplicate_prompt_from_history',
            data: {
              'historyLengthBefore': allHistory.length,
              'historyLengthAfter': recentHistory.length,
              'removedPromptLength': promptToUse.length,
            },
          );
          // #endregion
        }
      }

      // Get settings
      if (!mounted) return;
      final settingsService = context.read<SettingsService>();

      // #region agent log
      DebugLogger.logDataFlow(
        location: 'chat_view.dart:375',
        operation: 'sending_regenerate_to_api',
        data: {
          'promptLength': promptToUse.length,
          'historyLength': recentHistory.length,
          'historyMessageCounts': {
            'user': recentHistory.where((m) => m['role'] == 'user').length,
            'assistant':
                recentHistory.where((m) => m['role'] == 'assistant').length,
          },
          'totalHistoryChars': recentHistory.fold<int>(
              0, (sum, m) => sum + (m['content']?.length ?? 0)),
          'extractedFromConversation': extractedFromConversation,
        },
      );
      // #endregion

      // Call API with same prompt (use promptToUse which may have been extracted from conversation)
      final response = await apiService.askQuestionWithHistory(
        prompt: promptToUse,
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

      // #region agent log
      DebugLogger.logError(
        location: 'chat_view.dart:323',
        error: 'Failed to regenerate response',
        originalError: e,
        context: {
          'lastPrompt': _lastPrompt,
        },
      );
      // #endregion

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

        // #region agent log
        try {
          final logFile = File(
              r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
          final lastMessageLength =
              messages.isNotEmpty ? messages.last.content.length : 0;
          final logEntry =
              '{"sessionId":"debug-session","runId":"run1","hypothesisId":"G","location":"chat_view.dart:262","message":"ChatView build","data":{"messageCount":${messages.length},"lastMessageLength":$lastMessageLength,"lastRole":"${messages.isNotEmpty ? messages.last.role : "none"}"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
          logFile.writeAsStringSync(logEntry, mode: FileMode.append);
        } catch (_) {}
        // #endregion

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
                      onSubmitted: (_) {
                        // #region agent log
                        DebugLogger.logUserInteraction(
                          location: 'chat_view.dart:367',
                          action: 'text_field_submitted',
                          data: {'textLength': _textController.text.length},
                        );
                        // #endregion
                        _sendMessage();
                      },
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
                    onPressed: _isLoading
                        ? null
                        : () {
                            // #region agent log
                            DebugLogger.logUserInteraction(
                              location: 'chat_view.dart:381',
                              action: 'send_button_clicked',
                              data: {'isLoading': _isLoading},
                            );
                            // #endregion
                            _sendMessage();
                          },
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
