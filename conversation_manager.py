import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from uuid import uuid4

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

_console = logging.StreamHandler()
_console.setFormatter(logging.Formatter(
    "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
))
logger.addHandler(_console)

# Directory to store conversations
CONVERSATIONS_DIR = Path("conversations")
CONVERSATIONS_DIR.mkdir(exist_ok=True)


class ConversationManager:
    """Manages conversation storage and retrieval."""

    @staticmethod
    def create_conversation() -> str:
        """Create a new conversation and return its ID."""
        conversation_id = str(uuid4())
        conversation = {
            "id": conversation_id,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "messages": []
        }
        ConversationManager.save_conversation(conversation)
        logger.info(f"Created new conversation: {conversation_id}")
        return conversation_id

    @staticmethod
    def save_conversation(conversation: Dict) -> None:
        """Save a conversation to disk."""
        conversation_id = conversation["id"]
        conversation["updated_at"] = datetime.now().isoformat()
        file_path = CONVERSATIONS_DIR / f"{conversation_id}.json"
        
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(conversation, f, indent=2, ensure_ascii=False)
            logger.debug(f"Saved conversation {conversation_id}")
        except Exception as e:
            logger.error(f"Failed to save conversation {conversation_id}: {e}")
            raise

    @staticmethod
    def load_conversation(conversation_id: str) -> Optional[Dict]:
        """Load a conversation by ID."""
        file_path = CONVERSATIONS_DIR / f"{conversation_id}.json"
        
        if not file_path.exists():
            logger.warning(f"Conversation {conversation_id} not found")
            return None
        
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                conversation = json.load(f)
            logger.debug(f"Loaded conversation {conversation_id}")
            return conversation
        except Exception as e:
            logger.error(f"Failed to load conversation {conversation_id}: {e}")
            return None

    @staticmethod
    def list_conversations() -> List[Dict]:
        """List all conversations with metadata."""
        conversations = []
        
        if not CONVERSATIONS_DIR.exists():
            return conversations
        
        for file_path in CONVERSATIONS_DIR.glob("*.json"):
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    conversation = json.load(f)
                    # Return only metadata, not full messages
                    conversations.append({
                        "id": conversation["id"],
                        "created_at": conversation.get("created_at"),
                        "updated_at": conversation.get("updated_at"),
                        "message_count": len(conversation.get("messages", []))
                    })
            except Exception as e:
                logger.warning(f"Failed to read conversation file {file_path}: {e}")
        
        # Sort by updated_at, most recent first
        conversations.sort(key=lambda x: x.get("updated_at", ""), reverse=True)
        return conversations

    @staticmethod
    def delete_conversation(conversation_id: str) -> bool:
        """Delete a conversation by ID."""
        file_path = CONVERSATIONS_DIR / f"{conversation_id}.json"
        
        if not file_path.exists():
            logger.warning(f"Conversation {conversation_id} not found for deletion")
            return False
        
        try:
            file_path.unlink()
            logger.info(f"Deleted conversation {conversation_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to delete conversation {conversation_id}: {e}")
            return False

    @staticmethod
    def add_message(conversation_id: str, role: str, content: str) -> Optional[Dict]:
        """Add a message to a conversation."""
        conversation = ConversationManager.load_conversation(conversation_id)
        if not conversation:
            return None
        
        conversation["messages"].append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })
        
        ConversationManager.save_conversation(conversation)
        return conversation

