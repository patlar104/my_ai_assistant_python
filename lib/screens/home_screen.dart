import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/conversation_service.dart';
import '../widgets/chat_view.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationService>().loadConversations();
    });
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Sidebar
          const ConversationSidebar(),
          
          // Main content
          Expanded(
            child: Stack(
              children: [
                const ChatView(),
                
                // Settings panel overlay
                if (_showSettings)
                  SettingsPanel(
                    onClose: () => setState(() => _showSettings = false),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showSettings
          ? null
          : FloatingActionButton(
              onPressed: _toggleSettings,
              tooltip: 'Settings',
              child: const Icon(Icons.settings),
            ),
    );
  }
}
