# Flutter Migration Summary

This document summarizes the migration from Flask web app to Flutter multi-platform application.

## What Changed

### Architecture
- **Before**: Single Flask web application with HTML/CSS/JS frontend
- **After**: Flutter frontend (Android, Windows, macOS, Linux) + Python Flask API backend

### Project Structure

#### New Flutter Structure
```
lib/
├── main.dart                    # App entry point
├── models/
│   └── conversation.dart       # Data models
├── screens/
│   └── home_screen.dart        # Main screen
├── services/
│   ├── api_service.dart        # HTTP client for backend API
│   ├── conversation_service.dart # Conversation state management
│   └── settings_service.dart   # Settings state management
└── widgets/
    ├── chat_view.dart          # Chat interface
    ├── conversation_sidebar.dart # Sidebar with conversation list
    ├── message_bubble.dart     # Message display widget
    ├── settings_panel.dart     # Settings overlay
    └── typing_indicator.dart   # Loading indicator
```

#### Backend Changes
- `web_ui.py`: Updated root route to return JSON API info instead of HTML template
- All other backend functionality remains the same (API endpoints unchanged)

### Key Features Ported

✅ **Conversation Management**
- Create new conversations
- List all conversations
- Load specific conversations
- Delete conversations
- Clear all conversations

✅ **Chat Interface**
- Send messages
- Receive AI responses
- Markdown rendering
- Code block highlighting
- Copy to clipboard
- Regenerate responses

✅ **Settings**
- Adjustable temperature (0.0-2.0)
- Adjustable max tokens (256-8192)
- Settings persist across app restarts

✅ **UI/UX**
- Material Design 3
- Dark mode support
- Responsive layout
- Sidebar navigation
- Settings panel overlay

## Dependencies

### Flutter (pubspec.yaml)
- `http`: HTTP client for API calls
- `provider`: State management
- `flutter_markdown`: Markdown rendering
- `shared_preferences`: Local settings storage
- `path_provider`: File system access
- `flutter_dotenv`: Environment variables
- `uuid`: UUID generation
- `intl`: Date formatting

### Python (requirements.txt)
- No changes - same dependencies as before

## Platform Support

### Android
- Minimum SDK: 21
- Configuration: `android/app/build.gradle`, `AndroidManifest.xml`

### Windows
- Configuration: `windows/CMakeLists.txt`
- Requires Visual Studio with C++ tools

### macOS
- Configuration: `macos/Runner/Configs/AppInfo.xcconfig`
- Requires Xcode

### Linux
- Configuration: `linux/CMakeLists.txt`
- Requires CMake and GTK development libraries

## Running the Application

1. **Start Python Backend** (required):
   ```bash
   python web_ui.py
   ```

2. **Run Flutter App**:
   ```bash
   flutter pub get
   flutter run -d <platform>
   ```

## API Compatibility

The Flutter app uses the same API endpoints as the original web app:
- `POST /ask` - Send prompt to AI
- `GET /conversations` - List conversations
- `POST /conversations/new` - Create conversation
- `GET /conversations/<id>` - Get conversation
- `DELETE /conversations/<id>` - Delete conversation

## Migration Notes

- The Python backend now serves as a pure API (no HTML templates)
- All UI is handled by Flutter
- Conversation storage format remains the same (JSON files)
- Settings are stored in Flutter's SharedPreferences (not backend)
- The app defaults to `http://127.0.0.1:5000` for the API, but can be configured via `.env`

## Next Steps (Optional Enhancements)

- [ ] Add offline mode with local conversation storage
- [ ] Implement streaming responses for real-time updates
- [ ] Add export/import conversation functionality
- [ ] Support multiple API endpoints (load balancing)
- [ ] Add authentication/authorization
- [ ] Implement push notifications (mobile)
- [ ] Add voice input/output
- [ ] Support file attachments
