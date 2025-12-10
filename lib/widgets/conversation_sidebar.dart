import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/conversation_service.dart';

class ConversationSidebar extends StatefulWidget {
  const ConversationSidebar({super.key});

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ConversationService>(
      builder: (context, conversationService, _) {
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Conversations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),

              // New conversation button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: conversationService.isLoading
                        ? null
                        : () async {
                            try {
                              await conversationService.createNewConversation();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('New Conversation'),
                  ),
                ),
              ),

              // Conversations list
              Expanded(
                child: conversationService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : conversationService.conversations.isEmpty
                        ? Center(
                            child: Text(
                              'No conversations yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: conversationService.conversations.length,
                            itemBuilder: (context, index) {
                              final conv = conversationService.conversations[index];
                              final isActive = conv.id == conversationService.currentConversationId;

                              return InkWell(
                                onTap: () async {
                                  try {
                                    await conversationService.loadConversation(conv.id);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  color: isActive
                                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conv.messageCount > 0
                                                  ? 'Conversation (${conv.messageCount} ${conv.messageCount == 1 ? 'message' : 'messages'})'
                                                  : 'New Conversation',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: isActive
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(conv.updatedAt),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Conversation'),
                                              content: const Text(
                                                  'Are you sure you want to delete this conversation?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirmed == true) {
                                            try {
                                              await conversationService.deleteConversation(conv.id);
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
