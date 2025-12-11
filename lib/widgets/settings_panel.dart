import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/conversation_service.dart';
import '../utils/debug_logger.dart';

class SettingsPanel extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsPanel({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, _) {
        final temperature = settingsService.temperature;
        final maxTokens = settingsService.maxTokens;

        return _buildSettingsContent(
            context, settingsService, temperature, maxTokens);
      },
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    SettingsService settingsService,
    double temperature,
    int maxTokens,
  ) {
    return Stack(
      children: [
        // Overlay
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black54,
          ),
        ),

        // Settings panel
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 400,
            color: Theme.of(context).colorScheme.surface,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () {
                          // #region agent log
                          DebugLogger.logUserInteraction(
                            location: 'settings_panel.dart:71',
                            action: 'settings_close_button_clicked',
                          );
                          // #endregion
                          onClose();
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Model section
                      _buildSection(
                        context,
                        title: 'Model',
                        children: [
                          Text(
                            'Current model: Gemini 2.5 Flash',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Model selection coming soon',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Response settings
                      _buildSection(
                        context,
                        title: 'Response Settings',
                        children: [
                          // Temperature
                          Text(
                            'Temperature: ${temperature.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Controls creativity (0.0 = focused, 2.0 = creative)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                          Slider(
                            value: temperature,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            label: temperature.toStringAsFixed(1),
                            onChanged: (value) {
                              // #region agent log
                              DebugLogger.logUserInteraction(
                                location: 'settings_panel.dart:134',
                                action: 'temperature_slider_changed',
                                data: {
                                  'oldValue': temperature,
                                  'newValue': value,
                                },
                              );
                              // #endregion
                              settingsService.setTemperature(value);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Max tokens
                          Text(
                            'Max Tokens: $maxTokens',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Maximum response length (256-8192)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                          Slider(
                            value: maxTokens.toDouble(),
                            min: 256,
                            max: 8192,
                            divisions: 31,
                            label: maxTokens.toString(),
                            onChanged: (value) {
                              final newValue = value.round();
                              // #region agent log
                              DebugLogger.logUserInteraction(
                                location: 'settings_panel.dart:162',
                                action: 'max_tokens_slider_changed',
                                data: {
                                  'oldValue': maxTokens,
                                  'newValue': newValue,
                                },
                              );
                              // #endregion
                              settingsService.setMaxTokens(newValue);
                            },
                          ),
                          const SizedBox(height: 8),
                          _MaxTokensTextField(
                            value: maxTokens,
                            onChanged: (value) {
                              if (value >= 256 && value <= 8192) {
                                settingsService.setMaxTokens(value);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Conversations section
                      _buildSection(
                        context,
                        title: 'Conversations',
                        children: [
                          Text(
                            'Manage your conversation history',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Consumer<ConversationService>(
                            builder: (context, conversationService, _) {
                              return ElevatedButton(
                                onPressed: conversationService.isLoading
                                    ? null
                                    : () async {
                                        // #region agent log
                                        DebugLogger.logUserInteraction(
                                          location: 'settings_panel.dart:192',
                                          action:
                                              'clear_all_conversations_button_clicked',
                                        );
                                        // #endregion

                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Clear All Conversations'),
                                            content: const Text(
                                                'Are you sure you want to delete ALL conversations? This cannot be undone.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  // #region agent log
                                                  DebugLogger.logDialog(
                                                    location:
                                                        'settings_panel.dart:204',
                                                    action:
                                                        'clear_all_dialog_cancelled',
                                                    dialogType:
                                                        'clear_all_conversations',
                                                    result: false,
                                                  );
                                                  // #endregion
                                                  Navigator.pop(context, false);
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  // #region agent log
                                                  DebugLogger.logDialog(
                                                    location:
                                                        'settings_panel.dart:208',
                                                    action:
                                                        'clear_all_dialog_confirmed',
                                                    dialogType:
                                                        'clear_all_conversations',
                                                    result: true,
                                                  );
                                                  // #endregion
                                                  Navigator.pop(context, true);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete All'),
                                              ),
                                            ],
                                          ),
                                        );

                                        // #region agent log
                                        DebugLogger.logDialog(
                                          location: 'settings_panel.dart:216',
                                          action: 'clear_all_dialog_closed',
                                          dialogType: 'clear_all_conversations',
                                          result: confirmed,
                                        );
                                        // #endregion

                                        if (confirmed == true &&
                                            context.mounted) {
                                          try {
                                            await conversationService
                                                .clearAllConversations();

                                            // #region agent log
                                            DebugLogger.logUserInteraction(
                                              location:
                                                  'settings_panel.dart:220',
                                              action:
                                                  'all_conversations_cleared',
                                            );
                                            // #endregion

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'All conversations deleted.'),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            // #region agent log
                                            DebugLogger.logError(
                                              location:
                                                  'settings_panel.dart:228',
                                              error:
                                                  'Failed to clear all conversations',
                                              originalError: e,
                                            );
                                            // #endregion

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Clear All Conversations'),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // About section
                      _buildSection(
                        context,
                        title: 'About',
                        children: [
                          Text(
                            'My AI Assistant v1.0',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Powered by Gemini 2.5 Flash',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _MaxTokensTextField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _MaxTokensTextField({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_MaxTokensTextField> createState() => _MaxTokensTextFieldState();
}

class _MaxTokensTextFieldState extends State<_MaxTokensTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_MaxTokensTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Max Tokens',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          // #region agent log
          DebugLogger.logUserInteraction(
            location: 'settings_panel.dart:348',
            action: 'max_tokens_text_field_changed',
            data: {
              'oldValue': widget.value,
              'newValue': intValue,
            },
          );
          // #endregion
          widget.onChanged(intValue);
        }
      },
    );
  }
}
