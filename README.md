# My AI Assistant

A multi-platform AI assistant application powered by Google Gemini, built with Flutter for Android, Windows, macOS, and Linux. The backend uses Python/Flask to handle AI interactions via the official `google-genai` SDK.

## Features
- **Multi-platform support**: Android, Windows, macOS, and Linux
- **Modern Flutter UI**: Beautiful, responsive interface with Material Design 3
- **Context-aware prompts**: Marks political/current-event queries as research-focused when applicable
- **Conversation management**: Create, view, and delete multiple conversations
- **Settings panel**: Adjustable temperature and max tokens for response customization
- **Markdown support**: Renders assistant responses with markdown formatting and code highlighting
- **Python backend API**: RESTful API for AI interactions (can run locally or remotely)

## Architecture

This project consists of two main components:

1. **Flutter Frontend** (`lib/`): Cross-platform mobile and desktop application
2. **Python Backend** (`web_ui.py`, `assistant_core.py`): REST API server for Gemini AI interactions

## Prerequisites

### For Flutter App
- Flutter SDK 3.0.0 or higher
- Dart SDK (included with Flutter)
- Platform-specific tools:
  - **Android**: Android Studio with Android SDK
  - **Windows**: Visual Studio with C++ tools
  - **macOS**: Xcode
  - **Linux**: CMake, GTK development libraries

### For Python Backend
- Python 3.11+
- A Google Gemini API key

## Setup

### 1. Python Backend Setup

1. Create a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file in the project root:
   ```env
   GEMINI_API_KEY=your-key-here
   FLASK_DEBUG=true
   # Optional: ASSISTANT_EXTRA_CONTEXT="Any additional standing instructions you want prepended"
   # Optional: API_BASE_URL=http://127.0.0.1:5000  (for Flutter app)
   ```

4. Start the backend server:
   ```bash
   python web_ui.py
   ```
   The API will be available at `http://127.0.0.1:5000`

### 2. Flutter App Setup

1. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

2. (Optional) Configure API base URL in `.env`:
   ```env
   API_BASE_URL=http://127.0.0.1:5000
   ```
   If not set, the app defaults to `http://127.0.0.1:5000`

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

1. **Start the Python backend** (required):
   ```bash
   python web_ui.py
   ```

2. **Run the Flutter app** on your desired platform (see above)

The Flutter app will connect to the backend API running on `http://127.0.0.1:5000` by default.

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
├── web_ui.py              # Flask API server
├── assistant_core.py      # Gemini AI integration
├── conversation_manager.py # Conversation storage
└── requirements.txt       # Python dependencies
```

## Testing

### Python Backend Tests
```bash
pytest
```
Tests are written to avoid real Gemini calls, so they can run offline.

### Flutter Tests
```bash
flutter test
```

## Quick CLI Test

Test the backend connectivity:
```bash
python assistant.py
```
It sends a sample query and prints the raw response.

## Notes

- The Flutter app requires the Python backend to be running
- For production, you may want to deploy the Python backend to a server and update `API_BASE_URL` in the Flutter app
- The backend API is now API-only (no HTML templates) and designed to be consumed by the Flutter app
