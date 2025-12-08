import os

os.environ.setdefault("GEMINI_API_KEY", "test-key")

import web_ui


def test_index_route_returns_html():
    client = web_ui.app.test_client()
    resp = client.get("/")

    assert resp.status_code == 200
    assert b"My AI Assistant" in resp.data


def test_ask_route_success(monkeypatch):
    client = web_ui.app.test_client()
    monkeypatch.setattr(web_ui, "ask_gemini", lambda prompt: "Hi there")

    resp = client.post("/ask", json={"prompt": "Hello"})

    assert resp.status_code == 200
    assert resp.get_json() == {"response": "Hi there"}


def test_ask_route_handles_assistant_error(monkeypatch):
    client = web_ui.app.test_client()

    def _raise(_prompt):
        raise web_ui.AssistantError("Nope")

    monkeypatch.setattr(web_ui, "ask_gemini", _raise)

    resp = client.post("/ask", json={"prompt": "Hello"})

    assert resp.status_code == 400
    assert resp.get_json()["error"] == "Nope"
