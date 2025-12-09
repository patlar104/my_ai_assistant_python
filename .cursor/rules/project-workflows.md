# My AI Assistant - Project Workflows

This document defines project-specific commands and workflows for the My AI Assistant Python project.

## Project Overview
A lightweight Flask web UI that wraps Google Gemini API for personal research/chat assistance. The project includes context-aware prompt augmentation, built-in date/time injection, and both web UI and CLI interfaces.

## Environment Setup

### Initial Setup
```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Linux/Mac:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file with required variables
# GEMINI_API_KEY=your-key-here
# Optional: FLASK_DEBUG=true
# Optional: ASSISTANT_EXTRA_CONTEXT="Additional instructions"
```

## Common Commands

### Running the Web UI
```bash
# Start the Flask development server
python web_ui.py

# Server runs on http://127.0.0.1:5000
```

### CLI Testing
```bash
# Quick connectivity test to Gemini API
python assistant.py
```

### Testing
```bash
# Run all tests
pytest

# Run tests with verbose output
pytest -v

# Run specific test file
pytest tests/test_assistant_core.py

# Run tests with coverage (if coverage is installed)
pytest --cov=assistant_core --cov=web_ui
```

## Development Workflows

### Adding New Features
1. Create feature branch: `git checkout -b feature/your-feature-name`
2. Make changes following existing code patterns
3. Add/update tests in `tests/` directory
4. Run tests: `pytest`
5. Test web UI manually: `python web_ui.py`
6. Commit and push changes

### Modifying Assistant Behavior
- Core logic: Edit `assistant_core.py`
  - Modify `BASE_SYSTEM_PROMPT_TEMPLATE` for system instructions
  - Adjust keyword sets (`RESEARCH_KEYWORDS`, `SENSITIVE_KEYWORDS`, `TIME_SENSITIVE_KEYWORDS`)
  - Update `_build_contextual_prompt()` for prompt augmentation
- Model configuration: Change `DEFAULT_MODEL` in `assistant_core.py`
- Safety settings: Modify `RELAXED_SAFETY_SETTINGS` in `assistant_core.py`

### Web UI Changes
- Backend routes: Edit `web_ui.py`
- Frontend: Edit `templates/index.html` and `static/style.css`
- After changes, restart Flask server

### Testing Workflows
- All tests should avoid real Gemini API calls (use mocks)
- Test files are in `tests/` directory
- Use `conftest.py` for shared fixtures
- Run tests before committing changes

## Project Structure
- `assistant_core.py` - Core Gemini API integration and prompt logic
- `assistant.py` - CLI helper for quick API tests
- `web_ui.py` - Flask application with `/` and `/ask` routes
- `config.py` - Environment variable loading
- `templates/index.html` - Frontend UI
- `static/style.css` - Styling
- `tests/` - Test suite
- `.env` - Environment variables (not in git)

## Key Dependencies
- `flask==3.1.2` - Web framework
- `google-genai==1.53.0` - Gemini API SDK
- `python-dotenv==1.2.1` - Environment variable management
- `pytest==9.0.2` - Testing framework

## Troubleshooting

### API Key Issues
- Ensure `.env` file exists in project root
- Verify `GEMINI_API_KEY` is set correctly
- Check that `.env` is not in `.gitignore` exclusion (it should be ignored)

### Import Errors
- Activate virtual environment: `.venv\Scripts\activate` (Windows) or `source .venv/bin/activate` (Linux/Mac)
- Reinstall dependencies: `pip install -r requirements.txt`

### Flask Server Issues
- Check if port 5000 is already in use
- Verify Flask is installed: `pip list | grep flask`
- Enable debug mode: Set `FLASK_DEBUG=true` in `.env`

## Code Style Guidelines
- Follow PEP 8 Python style guide
- Use type hints where appropriate
- Add docstrings to functions and classes
- Keep functions focused and single-purpose
- Use logging instead of print statements for production code

