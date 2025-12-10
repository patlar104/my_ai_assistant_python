# My AI Assistant

A multi-platform AI assistant application powered by Google Gemini, built with Flutter for Android, Windows, macOS, and Linux. The app connects directly to the Gemini API - no backend server required!

## Features
- **Multi-platform support**: Android, Windows, macOS, and Linux
- **Modern Flutter UI**: Beautiful, responsive interface with Material Design 3
- **Context-aware prompts**: Marks political/current-event queries as research-focused when applicable
- **Conversation management**: Create, view, and delete multiple conversations
- **Settings panel**: Adjustable temperature and max tokens for response customization
- **Markdown support**: Renders assistant responses with markdown formatting and code highlighting
- **Direct Gemini integration**: Connects directly to Gemini API - no backend required

## Architecture

This is a standalone Flutter application that connects directly to Google's Gemini API:

1. **Flutter App** (`lib/`): Cross-platform mobile and desktop application with direct Gemini API integration
2. **Local Storage**: Conversations are stored locally on the device using platform-specific storage

## Prerequisites

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK (included with Flutter)
- A Google Gemini API key
- Platform-specific tools:
  - **Android**: Android Studio with Android SDK
  - **Windows**: Visual Studio with C++ tools
  - **macOS**: Xcode
  - **Linux**: CMake, GTK development libraries

## Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. Create a `.env` file in the project root:
   ```env
   GEMINI_API_KEY=your-key-here
   # Optional: ASSISTANT_EXTRA_CONTEXT="Any additional standing instructions you want prepended"
   ```
   
   **Important**: Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

3. Run the Flutter app:

   **Android:**
   ```bash
   flutter run -d android
   ```

   **Windows:**
   ```bash
   flutter run -d windows
   ```

   **macOS:**
   ```bash
   flutter run -d macos
   ```

   **Linux:**
   ```bash
   flutter run -d linux
   ```

   Or build for release:
   ```bash
   flutter build apk          # Android
   flutter build windows      # Windows
   flutter build macos        # macOS
   flutter build linux        # Linux
   ```

## Running the Application

Simply run the Flutter app on your desired platform (see above). The app connects directly to the Gemini API - no backend server needed!

**Note**: Make sure your `.env` file contains a valid `GEMINI_API_KEY`.

## Project Structure

```
.
├── lib/                    # Flutter application code
│   ├── main.dart          # App entry point
│   ├── models/            # Data models
│   ├── screens/           # App screens
│   ├── services/          # API and business logic
│   └── widgets/           # Reusable UI components
├── android/               # Android platform configuration
├── windows/               # Windows platform configuration
├── macos/                 # macOS platform configuration
├── linux/                 # Linux platform configuration
├── lib/services/
│   ├── gemini_service.dart      # Direct Gemini API integration
│   └── local_conversation_storage.dart # Local conversation storage
└── .env                    # Environment variables (GEMINI_API_KEY)
```

## Testing

### Flutter Tests
```bash
flutter test
```

## Notes

- The app connects directly to Google's Gemini API - no backend server required
- Conversations are stored locally on the device
- The Python backend files (`web_ui.py`, `assistant_core.py`, etc.) are no longer used but remain in the repository for reference
- Make sure your `.env` file contains a valid `GEMINI_API_KEY` from [Google AI Studio](https://makersuite.google.com/app/apikey)
