# My AI Assistant

This project is a lightweight Flask web UI that turns Google Gemini into a
personal research/chat assistant. The backend wraps the official `google-genai`
SDK, adds simple logging/error handling, and exposes a `/ask` endpoint consumed
by the single-page interface in `templates/index.html`.

## Prerequisites
- Python 3.11+ (the UI copy references 3.13, but any modern 3.11+ build works)
- A Google Gemini API key

## Setup
1. Clone or download this repository, then open a terminal in its root folder.
2. (Recommended) Create a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Windows: .venv\Scripts\activate
   ```
3. Install the dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Provide your API credentials by creating a `.env` file in the project root:
   ```
   GEMINI_API_KEY=your-key-here
   # Optional: FLASK_DEBUG=true
   ```

## Running the web UI
```bash
python web_ui.py
```
Then open http://127.0.0.1:5000 in your browser. Enter a prompt in the text box
and the assistant will respond using the Gemini model configured in
`assistant_core.DEFAULT_MODEL`.

### Quick CLI smoke test
If you only want to test connectivity to Gemini, run:
```bash
python assistant.py
```
It sends a sample query and prints the raw response.
