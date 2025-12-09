import os
from types import SimpleNamespace

os.environ.setdefault("GEMINI_API_KEY", "test-key")

import assistant_core
import pytest


def _set_fake_client(monkeypatch, response):
    class FakeModels:
        def generate_content(self, *args, **kwargs):
            return response

    class FakeClient:
        models = FakeModels()

    monkeypatch.setattr(assistant_core, "client", FakeClient())


def test_ask_gemini_empty_prompt_raises():
    with pytest.raises(assistant_core.AssistantError):
        assistant_core.ask_gemini("   ")


def test_ask_gemini_returns_response_text(monkeypatch):
    response = SimpleNamespace(text="Hello world")
    _set_fake_client(monkeypatch, response)

    result = assistant_core.ask_gemini("Tell me something fun.")

    assert result == "Hello world"


def test_ask_gemini_with_conversation_history(monkeypatch):
    response = SimpleNamespace(text="Hello again")
    _set_fake_client(monkeypatch, response)

    history = [
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi there!"}
    ]
    result = assistant_core.ask_gemini("How are you?", conversation_history=history)

    assert result == "Hello again"


def test_ask_gemini_falls_back_to_candidate_parts(monkeypatch):
    part = SimpleNamespace(text="Fallback text")
    content = SimpleNamespace(parts=[part])
    candidate = SimpleNamespace(content=content)
    response = SimpleNamespace(text=None, candidates=[candidate])
    _set_fake_client(monkeypatch, response)

    result = assistant_core.ask_gemini("Give me more info.")

    assert result == "Fallback text"


def test_ask_gemini_raises_if_response_empty(monkeypatch):
    response = SimpleNamespace(text=None, candidates=[])
    _set_fake_client(monkeypatch, response)

    with pytest.raises(assistant_core.AssistantError):
        assistant_core.ask_gemini("Need details.")


def test_contextual_prompt_includes_time_and_flags(monkeypatch):
    monkeypatch.setattr(
        assistant_core,
        "_current_datetime_strings",
        lambda: ("March 15, 2030", "10:00 UTC"),
    )
    monkeypatch.setattr(
        assistant_core,
        "EXTRA_ASSISTANT_CONTEXT",
        "Organization policy reminder.",
    )

    prompt = "Please research the current government policy timeline this week."
    contextual_prompt, meta = assistant_core._build_contextual_prompt(prompt)

    assert meta["is_sensitive"] is True
    assert meta["is_research"] is True
    assert meta["is_time_sensitive"] is True

    assert "March 15, 2030" in contextual_prompt
    assert "10:00 UTC" in contextual_prompt
    assert "Organization policy reminder." in contextual_prompt
    assert "timeliness" in contextual_prompt.lower()


def test_analyze_prompt_detects_flags():
    prompt = "Can you research today's election results?"
    is_sensitive, is_research, is_time_sensitive = assistant_core._analyze_prompt(prompt)

    assert is_sensitive is True
    assert is_research is True
    assert is_time_sensitive is True
