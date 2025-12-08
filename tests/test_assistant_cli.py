import os

os.environ.setdefault("GEMINI_API_KEY", "test-key")

import assistant


class DummyModels:
    def __init__(self, response_text=None, error=None):
        self._response_text = response_text
        self._error = error

    def generate_content(self, *args, **kwargs):
        if self._error:
            raise self._error
        return type("Resp", (), {"text": self._response_text})()


class DummyClient:
    def __init__(self, response_text=None, error=None):
        self.models = DummyModels(response_text=response_text, error=error)


def test_fetch_gemini_data_returns_text(monkeypatch):
    monkeypatch.setattr(assistant.genai, "Client", lambda api_key: DummyClient("ok"))

    assert assistant.fetch_gemini_data("Hi") == "ok"


def test_fetch_gemini_data_handles_exception(monkeypatch):
    monkeypatch.setattr(
        assistant.genai,
        "Client",
        lambda api_key: DummyClient(error=ValueError("boom")),
    )

    result = assistant.fetch_gemini_data("Hi")

    assert "An error occurred" in result
