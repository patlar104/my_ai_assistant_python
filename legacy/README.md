# Legacy Flask Backend

This directory contains the original Flask backend implementation that has been replaced by the Flutter app's direct Gemini API integration.

## Contents

- `backend/` - Python Flask backend files
  - `web_ui.py` - Flask web server with REST API endpoints
  - `assistant_core.py` - Core Gemini API integration logic
  - `conversation_manager.py` - Conversation storage management
  - `assistant.py` - CLI helper script
  - `config.py` - Configuration management

- `templates/` - HTML templates for web UI
  - `index.html` - Web interface

- `static/` - Static assets
  - `style.css` - CSS styling

## Status

**These files are no longer used by the Flutter application.** They are preserved here for reference only.

The Flutter app now:
- Connects directly to the Gemini API (no backend server needed)
- Stores conversations locally on the device
- Provides a native cross-platform experience

## Migration

The functionality from these files has been migrated to:
- `lib/services/gemini_service.dart` - Replaces `assistant_core.py`
- `lib/services/local_conversation_storage.dart` - Replaces `conversation_manager.py`
- Flutter widgets - Replace the web UI

## Running the Legacy Backend (Optional)

If you want to run the legacy Flask backend for reference:

```bash
# Install Python dependencies
pip install -r requirements.txt

# Set up environment
# Create .env file with GEMINI_API_KEY

# Run Flask server
python legacy/backend/web_ui.py
```

**Note**: The Flask backend and Flutter app use separate conversation storage locations and will not share data.

