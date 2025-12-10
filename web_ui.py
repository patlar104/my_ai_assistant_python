import logging
import os
import json
from datetime import datetime

from flask import Flask, jsonify, render_template, request, session
from dotenv import load_dotenv

from assistant_core import ask_gemini, AssistantError
from conversation_manager import ConversationManager

load_dotenv()

# #region agent log
DEBUG_LOG_PATH = r"c:\Users\patri\OneDrive\Documents\GitHub\my_ai_assistant_python\.cursor\debug.log"
def _debug_log(session_id, run_id, hypothesis_id, location, message, data):
    try:
        with open(DEBUG_LOG_PATH, "a", encoding="utf-8") as f:
            f.write(json.dumps({
                "sessionId": session_id,
                "runId": run_id,
                "hypothesisId": hypothesis_id,
                "location": location,
                "message": message,
                "data": data,
                "timestamp": int(datetime.now().timestamp() * 1000)
            }) + "\n")
    except: pass
# #endregion

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-secret-key-change-in-production")

logger = logging.getLogger("web_ui")
logger.setLevel(logging.INFO)
# Disable propagation to prevent duplicate logs from root logger
logger.propagate = False

# Use a process-level flag to ensure logging is only configured once per process
# This prevents duplicate handlers when Flask's reloader re-imports modules
if not hasattr(logging, '_web_ui_configured'):
    # Remove any existing StreamHandler instances to prevent duplicates
    for handler in list(logger.handlers):
        if isinstance(handler, logging.StreamHandler):
            logger.removeHandler(handler)
    
    _console = logging.StreamHandler()
    _console.setFormatter(logging.Formatter(
        "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
    ))
    logger.addHandler(_console)
    logging._web_ui_configured = True


@app.route("/", methods=["GET"])
def index():
    """API endpoint - returns JSON indicating this is an API server."""
    return jsonify({
        "message": "My AI Assistant API",
        "version": "1.0.0",
        "endpoints": {
            "/ask": "POST - Send a prompt to the AI assistant",
            "/conversations": "GET - List all conversations",
            "/conversations/new": "POST - Create a new conversation",
            "/conversations/<id>": "GET - Get a specific conversation",
            "/conversations/<id>": "DELETE - Delete a conversation",
        }
    })


@app.route("/ask", methods=["POST"])
def ask():
    # #region agent log
    _debug_log("debug-session", "run1", "A", "web_ui.py:52", "Flask /ask endpoint called", {"method": request.method, "has_json": request.is_json})
    # #endregion
    data = request.get_json(silent=True) or {}
    prompt = data.get("prompt", "")
    conversation_id = data.get("conversation_id") or session.get("conversation_id")
    temperature = data.get("temperature", 0.7)
    max_tokens = data.get("max_tokens", 2048)
    
    # #region agent log
    _debug_log("debug-session", "run1", "A", "web_ui.py:59", "Request parsed", {"prompt_len": len(prompt), "conversation_id": conversation_id, "temperature": temperature, "max_tokens": max_tokens})
    # #endregion
    logger.info("/ask received prompt length=%d, conversation_id=%s, temperature=%.2f, max_tokens=%d", 
                len(prompt), conversation_id, temperature, max_tokens)

    # Create new conversation if none exists
    if not conversation_id:
        conversation_id = ConversationManager.create_conversation()
        session["conversation_id"] = conversation_id

    try:
        # Load conversation history
        conversation = ConversationManager.load_conversation(conversation_id)
        if not conversation:
            # Conversation was deleted, create a new one
            conversation_id = ConversationManager.create_conversation()
            session["conversation_id"] = conversation_id
            conversation = ConversationManager.load_conversation(conversation_id)
            # Verify the second load succeeded
            if not conversation:
                raise AssistantError("Failed to create or load conversation. Please try again.")
        
        # Get conversation history (last 20 messages to avoid token limits)
        history = conversation.get("messages", [])[-20:]
        conversation_history = [{"role": msg["role"], "content": msg["content"]} 
                               for msg in history]
        
        # Get response from Gemini with configurable settings
        # #region agent log
        _debug_log("debug-session", "run1", "B", "web_ui.py:85", "Calling ask_gemini", {"prompt_len": len(prompt), "history_count": len(conversation_history)})
        # #endregion
        answer = ask_gemini(
            prompt, 
            conversation_history=conversation_history,
            temperature=temperature,
            max_output_tokens=max_tokens
        )
        # #region agent log
        _debug_log("debug-session", "run1", "B", "web_ui.py:92", "ask_gemini returned", {"answer_len": len(answer) if answer else 0})
        # #endregion
        
        # Save user message and assistant response
        ConversationManager.add_message(conversation_id, "user", prompt)
        ConversationManager.add_message(conversation_id, "assistant", answer)
        
        return {
            "response": answer,
            "conversation_id": conversation_id
        }
    except AssistantError as e:
        # #region agent log
        _debug_log("debug-session", "run1", "C", "web_ui.py:101", "AssistantError caught", {"error": str(e)})
        # #endregion
        logger.warning("AssistantError: %s", e)
        return {"error": str(e)}, 400
    except Exception as e:
        # #region agent log
        _debug_log("debug-session", "run1", "D", "web_ui.py:105", "Unhandled exception", {"error": str(e), "type": type(e).__name__})
        # #endregion
        logger.exception("Unhandled exception in /ask: %s", e)
        return {
            "error": "An unexpected error occurred while processing your request."
        }, 500


@app.route("/conversations", methods=["GET"])
def list_conversations():
    """List all conversations."""
    try:
        conversations = ConversationManager.list_conversations()
        return jsonify({"conversations": conversations})
    except Exception as e:
        logger.exception("Error listing conversations: %s", e)
        return {"error": "Failed to list conversations"}, 500


@app.route("/conversations/new", methods=["POST"])
def new_conversation():
    """Create a new conversation."""
    try:
        conversation_id = ConversationManager.create_conversation()
        session["conversation_id"] = conversation_id
        return jsonify({
            "conversation_id": conversation_id,
            "message": "New conversation created"
        })
    except Exception as e:
        logger.exception("Error creating conversation: %s", e)
        return {"error": "Failed to create conversation"}, 500


@app.route("/conversations/<conversation_id>", methods=["GET"])
def get_conversation(conversation_id):
    """Get a specific conversation."""
    try:
        conversation = ConversationManager.load_conversation(conversation_id)
        if not conversation:
            return {"error": "Conversation not found"}, 404
        return jsonify(conversation)
    except Exception as e:
        logger.exception("Error getting conversation: %s", e)
        return {"error": "Failed to get conversation"}, 500


@app.route("/conversations/<conversation_id>", methods=["DELETE"])
def delete_conversation(conversation_id):
    """Delete a conversation."""
    try:
        success = ConversationManager.delete_conversation(conversation_id)
        if not success:
            return {"error": "Conversation not found"}, 404
        
        # Clear session if deleting current conversation
        if session.get("conversation_id") == conversation_id:
            session.pop("conversation_id", None)
        
        return jsonify({"message": "Conversation deleted"})
    except Exception as e:
        logger.exception("Error deleting conversation: %s", e)
        return {"error": "Failed to delete conversation"}, 500


if __name__ == "__main__":
    debug_flag = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    app.run(host="127.0.0.1", port=5000, debug=debug_flag)