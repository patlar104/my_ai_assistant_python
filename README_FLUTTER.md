# My AI Assistant - Flutter Edition

This is a Flutter application that provides a multi-platform AI assistant powered by Google Gemini. The app runs on Android, iOS, Windows, macOS, and Linux.

## Features

- **Multi-platform support**: Android, iOS, Windows, macOS, and Linux
- **Context-aware AI**: Intelligent prompt augmentation that marks political/current-event queries as research-focused
- **Conversation management**: Create, view, and delete conversations
- **Customizable settings**: Adjust temperature and max tokens for AI responses
- **Modern UI**: Material Design 3 with dark mode support
- **Markdown support**: Rich text rendering with code syntax highlighting

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- A Google Gemini API key

## Setup

1. **Install Flutter**: Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install)

2. **Clone or download this repository**

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Configure API key**: Create a `.env` file in the project root:
   ```env
   GEMINI_API_KEY=your_real_api_key_here
   ASSISTANT_EXTRA_CONTEXT=Optional additional instructions
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

## Platform-Specific Setup

### Android

1. Ensure you have Android Studio installed
2. Set up an Android emulator or connect a physical device
3. Run `flutter run` or use Android Studio

### iOS (macOS only)

1. Ensure you have Xcode installed
2. Run `pod install` in the `ios` directory
3. Open the project in Xcode and configure signing
4. Run `flutter run`

### Windows

1. Enable Windows desktop support:
   ```bash
   flutter config --enable-windows-desktop
   ```
2. Run `flutter run -d windows`

### macOS

1. Enable macOS desktop support:
   ```bash
   flutter config --enable-macos-desktop
   ```
2. Run `flutter run -d macos`

### Linux

1. Install required dependencies (Ubuntu/Debian):
   ```bash
   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
   ```
2. Enable Linux desktop support:
   ```bash
   flutter config --enable-linux-desktop
   ```
3. Run `flutter run -d linux`

## Building for Production

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Windows

```bash
flutter build windows --release
```

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                  # Data models
│   └── conversation.dart
├── services/                # Business logic
│   ├── assistant_service.dart
│   └── conversation_service.dart
├── providers/               # State management
│   └── conversation_provider.dart
├── screens/                 # Screen widgets
│   └── home_screen.dart
└── widgets/                 # Reusable widgets
    ├── chat_message.dart
    ├── conversation_sidebar.dart
    └── settings_panel.dart
```

## Configuration

The app uses environment variables from a `.env` file:

- `GEMINI_API_KEY` (required): Your Google Gemini API key
- `ASSISTANT_EXTRA_CONTEXT` (optional): Additional instructions for the AI assistant

## Features Overview

### Conversation Management

- Create new conversations
- View conversation history
- Delete individual conversations
- Clear all conversations

### AI Settings

- **Temperature**: Controls creativity (0.0 = focused, 2.0 = creative)
- **Max Tokens**: Maximum response length (256-8192)

### UI Features

- Responsive sidebar for conversation list
- Settings panel for customization
- Markdown rendering for AI responses
- Dark mode support (follows system theme)

## Troubleshooting

### API Key Issues

If you see "GEMINI_API_KEY is not set", ensure:
1. The `.env` file exists in the project root
2. The file contains `GEMINI_API_KEY=your_key_here`
3. You've restarted the app after creating/modifying `.env`

### Build Issues

- Run `flutter clean` and then `flutter pub get`
- Ensure you have the latest Flutter SDK
- Check platform-specific requirements above

## Migration from Flask Version

This Flutter version replaces the previous Flask web application. Key differences:

- **Platform**: Native apps instead of web browser
- **Storage**: Local file storage using platform-specific directories
- **State Management**: Provider pattern instead of server sessions
- **UI**: Material Design 3 instead of custom HTML/CSS

The core functionality remains the same:
- Same Gemini API integration
- Same conversation management
- Same prompt analysis and context handling

## License

Same as the original project.
