import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/conversation.dart';
import '../utils/debug_logger.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRegenerate;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    // #region agent log
    try {
      final logFile = File(
          r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
      final logEntry =
          '{"sessionId":"debug-session","runId":"run1","hypothesisId":"H","location":"message_bubble.dart:18","message":"MessageBubble build","data":{"role":"${message.role}","contentLength":${message.content.length},"isUser":${message.role == "user"}},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
      logFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (_) {}
    // #endregion

    final isUser = message.role == 'user';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUser ? 'You' : 'Assistant',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isUser && onRegenerate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                // #region agent log
                                DebugLogger.logUserInteraction(
                                  location: 'message_bubble.dart:73',
                                  action: 'copy_button_clicked',
                                  data: {
                                    'messageLength': message.content.length,
                                    'role': message.role,
                                  },
                                );
                                // #endregion
                                _copyToClipboard(context);
                              },
                              tooltip: 'Copy',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 16),
                              onPressed: () {
                                // #region agent log
                                DebugLogger.logUserInteraction(
                                  location: 'message_bubble.dart:80',
                                  action: 'regenerate_button_clicked',
                                  data: {
                                    'messageLength': message.content.length,
                                    'role': message.role,
                                  },
                                );
                                // #endregion
                                onRegenerate?.call();
                              },
                              tooltip: 'Regenerate',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isUser)
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    _buildMarkdownContent(context, message.content),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, String content) {
    // #region agent log
    try {
      final logFile = File(
          r'c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log');
      final hasCodeBlock = content.contains('```');
      final codeBlockCount = '```'.allMatches(content).length ~/ 2;
      final preview = content.length > 500
          ? '${content.substring(0, 250)}...${content.substring(content.length - 250)}'
          : content;
      final logEntry =
          '{"sessionId":"debug-session","runId":"run1","hypothesisId":"H","location":"message_bubble.dart:115","message":"Building markdown content","data":{"contentLength":${content.length},"hasCodeBlock":$hasCodeBlock,"codeBlockCount":$codeBlockCount,"preview":"${preview.replaceAll('"', '\\"').replaceAll('\n', '\\n').substring(0, preview.length > 500 ? 500 : preview.length)}"},"timestamp":${DateTime.now().millisecondsSinceEpoch}}\n';
      logFile.writeAsStringSync(logEntry, mode: FileMode.append);
    } catch (_) {}
    // #endregion

    return MarkdownBody(
      data: content,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium,
        code: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(8),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: message.content));

      // #region agent log
      DebugLogger.logUserInteraction(
        location: 'message_bubble.dart:122',
        action: 'copy_to_clipboard_success',
        data: {'messageLength': message.content.length},
      );
      // #endregion

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard!')),
        );
      }
    } catch (e) {
      // #region agent log
      DebugLogger.logError(
        location: 'message_bubble.dart:122',
        error: 'Failed to copy to clipboard',
        originalError: e,
      );
      // #endregion
    }
  }
}
