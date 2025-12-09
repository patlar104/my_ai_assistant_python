import os

os.environ.setdefault("GEMINI_API_KEY", "test-key")
os.environ.setdefault("FLASK_SECRET_KEY", "test-secret-key")

import web_ui


def test_index_route_returns_html():
    client = web_ui.app.test_client()
    resp = client.get("/")

    assert resp.status_code == 200
    assert b"My AI Assistant" in resp.data


def test_ask_route_success(monkeypatch):
    client = web_ui.app.test_client()
    with client.session_transaction() as sess:
        sess['conversation_id'] = None
    
    def mock_ask_gemini(prompt, conversation_history=None):
        return "Hi there"
    
    monkeypatch.setattr(web_ui, "ask_gemini", mock_ask_gemini)
    monkeypatch.setattr(web_ui.ConversationManager, "create_conversation", lambda: "test-id")
    monkeypatch.setattr(web_ui.ConversationManager, "load_conversation", lambda _: {"id": "test-id", "messages": []})
    monkeypatch.setattr(web_ui.ConversationManager, "add_message", lambda *args: None)

    resp = client.post("/ask", json={"prompt": "Hello"})

    assert resp.status_code == 200
    data = resp.get_json()
    assert data["response"] == "Hi there"
    assert "conversation_id" in data


def test_ask_route_handles_assistant_error(monkeypatch):
    client = web_ui.app.test_client()
    
    def _raise(prompt, conversation_history=None):
        raise web_ui.AssistantError("Nope")

    monkeypatch.setattr(web_ui, "ask_gemini", _raise)
    monkeypatch.setattr(web_ui.ConversationManager, "create_conversation", lambda: "test-id")
    monkeypatch.setattr(web_ui.ConversationManager, "load_conversation", lambda _: {"id": "test-id", "messages": []})

    resp = client.post("/ask", json={"prompt": "Hello"})

    assert resp.status_code == 400
    assert resp.get_json()["error"] == "Nope"


def test_list_conversations_route(monkeypatch):
    client = web_ui.app.test_client()
    
    def mock_list():
        return [{"id": "test-1", "created_at": "2024-01-01", "message_count": 5}]
    
    monkeypatch.setattr(web_ui.ConversationManager, "list_conversations", mock_list)
    
    resp = client.get("/conversations")
    
    assert resp.status_code == 200
    data = resp.get_json()
    assert "conversations" in data
    assert len(data["conversations"]) == 1


def test_new_conversation_route(monkeypatch):
    client = web_ui.app.test_client()
    
    monkeypatch.setattr(web_ui.ConversationManager, "create_conversation", lambda: "new-id")
    
    resp = client.post("/conversations/new")
    
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["conversation_id"] == "new-id"


def test_get_conversation_route(monkeypatch):
    client = web_ui.app.test_client()
    
    mock_conv = {"id": "test-id", "messages": []}
    monkeypatch.setattr(web_ui.ConversationManager, "load_conversation", lambda _: mock_conv)
    
    resp = client.get("/conversations/test-id")
    
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["id"] == "test-id"


def test_delete_conversation_route(monkeypatch):
    client = web_ui.app.test_client()
    
    monkeypatch.setattr(web_ui.ConversationManager, "delete_conversation", lambda _: True)
    
    resp = client.delete("/conversations/test-id")
    
    assert resp.status_code == 200
    data = resp.get_json()
    assert "message" in data
