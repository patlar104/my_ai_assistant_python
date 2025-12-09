import json
import os
import tempfile
import shutil
from pathlib import Path

os.environ.setdefault("GEMINI_API_KEY", "test-key")

import conversation_manager
import pytest


@pytest.fixture
def temp_conversations_dir(monkeypatch):
    """Create a temporary directory for conversations."""
    temp_dir = tempfile.mkdtemp()
    monkeypatch.setattr(conversation_manager, "CONVERSATIONS_DIR", Path(temp_dir))
    yield temp_dir
    shutil.rmtree(temp_dir)


def test_create_conversation(temp_conversations_dir):
    """Test creating a new conversation."""
    conv_id = conversation_manager.ConversationManager.create_conversation()
    
    assert conv_id is not None
    assert len(conv_id) > 0
    
    # Check file was created
    conv_file = conversation_manager.CONVERSATIONS_DIR / f"{conv_id}.json"
    assert conv_file.exists()


def test_save_and_load_conversation(temp_conversations_dir):
    """Test saving and loading a conversation."""
    conv = {
        "id": "test-id",
        "created_at": "2024-01-01T00:00:00",
        "messages": [
            {"role": "user", "content": "Hello", "timestamp": "2024-01-01T00:00:00"},
            {"role": "assistant", "content": "Hi!", "timestamp": "2024-01-01T00:00:01"}
        ]
    }
    
    conversation_manager.ConversationManager.save_conversation(conv)
    
    loaded = conversation_manager.ConversationManager.load_conversation("test-id")
    
    assert loaded is not None
    assert loaded["id"] == "test-id"
    assert len(loaded["messages"]) == 2


def test_load_nonexistent_conversation(temp_conversations_dir):
    """Test loading a conversation that doesn't exist."""
    loaded = conversation_manager.ConversationManager.load_conversation("nonexistent")
    assert loaded is None


def test_list_conversations(temp_conversations_dir):
    """Test listing conversations."""
    # Create a few conversations
    conv1_id = conversation_manager.ConversationManager.create_conversation()
    conv2_id = conversation_manager.ConversationManager.create_conversation()
    
    # Add messages to one
    conversation_manager.ConversationManager.add_message(conv1_id, "user", "Test")
    
    conversations = conversation_manager.ConversationManager.list_conversations()
    
    assert len(conversations) == 2
    assert all("id" in conv for conv in conversations)
    assert all("created_at" in conv for conv in conversations)
    assert all("message_count" in conv for conv in conversations)


def test_delete_conversation(temp_conversations_dir):
    """Test deleting a conversation."""
    conv_id = conversation_manager.ConversationManager.create_conversation()
    
    # Verify it exists
    assert conversation_manager.ConversationManager.load_conversation(conv_id) is not None
    
    # Delete it
    success = conversation_manager.ConversationManager.delete_conversation(conv_id)
    assert success is True
    
    # Verify it's gone
    assert conversation_manager.ConversationManager.load_conversation(conv_id) is None


def test_delete_nonexistent_conversation(temp_conversations_dir):
    """Test deleting a conversation that doesn't exist."""
    success = conversation_manager.ConversationManager.delete_conversation("nonexistent")
    assert success is False


def test_add_message(temp_conversations_dir):
    """Test adding a message to a conversation."""
    conv_id = conversation_manager.ConversationManager.create_conversation()
    
    updated = conversation_manager.ConversationManager.add_message(conv_id, "user", "Hello")
    
    assert updated is not None
    assert len(updated["messages"]) == 1
    assert updated["messages"][0]["role"] == "user"
    assert updated["messages"][0]["content"] == "Hello"


def test_add_message_to_nonexistent_conversation(temp_conversations_dir):
    """Test adding a message to a conversation that doesn't exist."""
    result = conversation_manager.ConversationManager.add_message("nonexistent", "user", "Hello")
    assert result is None

