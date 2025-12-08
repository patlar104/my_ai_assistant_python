import assistant_core
import pytest


def test_ask_gemini_empty_prompt_raises():
    with pytest.raises(assistant_core.AssistantError):
        assistant_core.ask_gemini("   ")


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
