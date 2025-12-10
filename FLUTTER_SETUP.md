# Quick Start Guide - Flutter Migration

## What Changed?

Your Flask web application has been successfully migrated to a Flutter multi-platform application. The app now runs natively on:
- 📱 Android
- 📱 iOS  
- 🪟 Windows
- 🍎 macOS
- 🐧 Linux

## Quick Setup

1. **Install Flutter** (if not already installed):
   ```bash
   # Check Flutter installation
   flutter --version
   
   # If not installed, follow: https://docs.flutter.dev/get-started/install
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Key**:
   - Create a `.env` file in the project root
   - Add your Gemini API key:
     ```env
     GEMINI_API_KEY=your_real_api_key_here
     ASSISTANT_EXTRA_CONTEXT=
     ```

4. **Run the App**:
   ```bash
   # For mobile (Android/iOS)
   flutter run
   
   # For desktop platforms
   flutter run -d windows   # Windows
   flutter run -d macos     # macOS
   flutter run -d linux     # Linux
   ```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/
│   └── conversation.dart          # Data models
├── services/
│   ├── assistant_service.dart    # Gemini API integration
│   └── conversation_service.dart  # Conversation storage
├── providers/
│   └── conversation_provider.dart # State management
├── screens/
│   └── home_screen.dart          # Main chat screen
└── widgets/
    ├── chat_message.dart         # Message display
    ├── conversation_sidebar.dart # Sidebar widget
    └── settings_panel.dart       # Settings widget
```

## Key Features Preserved

✅ All original features are maintained:
- AI chat with Gemini 2.5 Flash
- Conversation management
- Temperature and max tokens settings
- Context-aware prompt analysis
- Markdown rendering

## New Capabilities

🌟 **Multi-platform**: One codebase, all platforms
🌟 **Native performance**: Better than web app
🌟 **Offline storage**: Conversations stored locally
🌟 **Modern UI**: Material Design 3 with dark mode

## Troubleshooting

### "GEMINI_API_KEY is not set" Error
- Ensure `.env` file exists in project root
- Check that `GEMINI_API_KEY=your_key` is set
- Restart the app after creating/modifying `.env`

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Platform-Specific Issues
See `README_FLUTTER.md` for detailed platform setup instructions.

## Next Steps

1. Test the app on your target platform
2. Customize the UI if needed
3. Build for production when ready:
   ```bash
   flutter build apk --release        # Android
   flutter build ios --release         # iOS
   flutter build windows --release     # Windows
   flutter build macos --release      # macOS
   flutter build linux --release       # Linux
   ```

## Migration Notes

- **No Flask server needed**: App runs standalone
- **Conversations**: Stored in platform-specific app data directories
- **API calls**: Direct to Gemini API (no backend server)
- **State**: Managed locally with Provider pattern

For detailed migration information, see `MIGRATION_GUIDE.md`.
