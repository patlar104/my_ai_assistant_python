# Migration Guide: Flask to Flutter

This guide explains the migration from the Flask web application to the Flutter multi-platform application.

## Architecture Changes

### Backend → Frontend
- **Before**: Flask server with REST API endpoints
- **After**: Direct API calls from Flutter app to Gemini API

### Storage
- **Before**: JSON files in `conversations/` directory
- **After**: JSON files in platform-specific app data directories:
  - Android: `/data/data/com.example.my_ai_assistant/app_flutter/conversations/`
  - iOS: `~/Library/Application Support/com.example.my_ai_assistant/conversations/`
  - Windows: `%APPDATA%\my_ai_assistant\conversations\`
  - macOS: `~/Library/Application Support/com.example.my_ai_assistant/conversations/`
  - Linux: `~/.local/share/my_ai_assistant/conversations/`

### State Management
- **Before**: Flask sessions and server-side state
- **After**: Provider pattern with local state management

## Code Mapping

### Python → Dart

| Python File | Dart File | Notes |
|------------|-----------|-------|
| `assistant_core.py` | `lib/services/assistant_service.dart` | Direct API calls instead of SDK |
| `conversation_manager.py` | `lib/services/conversation_service.dart` | Uses path_provider for platform paths |
| `web_ui.py` | `lib/screens/home_screen.dart` | Flutter widgets instead of HTML |
| `templates/index.html` | `lib/widgets/*.dart` | Split into multiple widget files |
| `config.py` | `lib/services/assistant_service.dart` | Environment variables via flutter_dotenv |

## API Changes

### Flask Endpoints → Direct Calls

| Flask Endpoint | Flutter Implementation |
|---------------|------------------------|
| `POST /ask` | `AssistantService.askGemini()` |
| `GET /conversations` | `ConversationService.listConversations()` |
| `POST /conversations/new` | `ConversationService.createConversation()` |
| `GET /conversations/<id>` | `ConversationService.loadConversation()` |
| `DELETE /conversations/<id>` | `ConversationService.deleteConversation()` |

## Key Differences

### 1. API Integration
- **Flask**: Used `google-genai` Python SDK
- **Flutter**: Direct HTTP calls to Gemini REST API

### 2. UI Framework
- **Flask**: HTML/CSS/JavaScript with custom styling
- **Flutter**: Material Design 3 widgets with built-in theming

### 3. Environment Variables
- **Flask**: `python-dotenv` package
- **Flutter**: `flutter_dotenv` package (requires asset configuration)

### 4. Logging
- **Flask**: Python logging module
- **Flutter**: Dart `print()` or logging packages (not implemented in migration)

### 5. Error Handling
- **Flask**: HTTP status codes and JSON error responses
- **Flutter**: Exceptions and user-friendly error messages

## Migration Steps

1. **Install Flutter SDK** (if not already installed)
2. **Create `.env` file** with your `GEMINI_API_KEY`
3. **Run `flutter pub get`** to install dependencies
4. **Test on your target platform**:
   - `flutter run` for mobile
   - `flutter run -d windows` for Windows
   - `flutter run -d macos` for macOS
   - `flutter run -d linux` for Linux

## Data Migration

Conversations from the Flask version are stored in `conversations/*.json` files. To migrate:

1. **Copy conversation files** from Flask `conversations/` directory
2. **Place them in the Flutter app's conversation directory** (platform-specific)
3. **Restart the app** to see migrated conversations

Note: The JSON format is compatible between both versions.

## Feature Parity

✅ All features from Flask version are implemented:
- ✅ AI chat with Gemini
- ✅ Conversation management (create, list, delete)
- ✅ Conversation history
- ✅ Temperature and max tokens settings
- ✅ Context-aware prompt analysis
- ✅ Markdown rendering
- ✅ Settings panel

## New Features in Flutter Version

- 🌟 **Multi-platform support**: One codebase for all platforms
- 🌟 **Native performance**: Better performance than web app
- 🌟 **Offline capability**: Conversations stored locally
- 🌟 **Material Design 3**: Modern UI with system theme support
- 🌟 **Better mobile experience**: Optimized for touch interfaces

## Breaking Changes

1. **No server required**: App runs standalone
2. **Different storage location**: Conversations stored in app data directories
3. **No web deployment**: Deploy as native apps instead
4. **Different build process**: Use Flutter build commands

## Troubleshooting

### API Key Issues
- Ensure `.env` file is in project root
- Check that `GEMINI_API_KEY` is set correctly
- Restart app after changing `.env`

### Platform-Specific Issues
- See platform-specific setup in `README_FLUTTER.md`
- Ensure platform desktop support is enabled
- Check platform-specific dependencies
