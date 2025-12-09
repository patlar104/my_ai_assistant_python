import logging
import os

from flask import Flask, jsonify, render_template, request, session
from dotenv import load_dotenv

from assistant_core import ask_gemini, AssistantError
from conversation_manager import ConversationManager

load_dotenv()

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
    return render_template("index.html")


@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json(silent=True) or {}
    prompt = data.get("prompt", "")
    conversation_id = data.get("conversation_id") or session.get("conversation_id")
    temperature = data.get("temperature", 0.7)
    max_tokens = data.get("max_tokens", 2048)
    
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
        answer = ask_gemini(
            prompt, 
            conversation_history=conversation_history,
            temperature=temperature,
            max_output_tokens=max_tokens
        )
        
        # Save user message and assistant response
        ConversationManager.add_message(conversation_id, "user", prompt)
        ConversationManager.add_message(conversation_id, "assistant", answer)
        
        return {
            "response": answer,
            "conversation_id": conversation_id
        }
    except AssistantError as e:
        logger.warning("AssistantError: %s", e)
        return {"error": str(e)}, 400
    except Exception as e:
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