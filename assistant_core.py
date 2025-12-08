import logging
import os
from datetime import datetime
from typing import Tuple

from dotenv import load_dotenv
from google import genai
from google.genai import types as genai_types

# Load environment variables from .env
load_dotenv()

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

_console = logging.StreamHandler()
_console.setFormatter(logging.Formatter(
    "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
))
logger.addHandler(_console)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
EXTRA_ASSISTANT_CONTEXT = (os.getenv("ASSISTANT_EXTRA_CONTEXT") or "").strip()

if not GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY is not set. Check your .env file.")
    raise RuntimeError("GEMINI_API_KEY environment variable is required.")

# Create a single shared client.
client = genai.Client(api_key=GEMINI_API_KEY)

# Choose a default model – adjust if you want Pro instead of Flash.
DEFAULT_MODEL = "gemini-2.5-flash"

BASE_SYSTEM_PROMPT_TEMPLATE = (
    "You are My AI Assistant, a neutral research aide. "
    "Offer balanced, factual summaries, cite reputable public sources when "
    "possible, and clearly label speculation. Decline policy-violating requests "
    "with a courteous explanation. Always assume the current date is {current_date} "
    "and the current time is {current_time} when answering time-sensitive questions."
)

RESEARCH_KEYWORDS = {
    "research",
    "study",
    "analyze",
    "analysis",
    "report",
    "paper",
    "whitepaper",
    "thesis",
    "investigate",
    "explain",
    "context",
    "academic",
}

SENSITIVE_KEYWORDS = {
    "election",
    "policy",
    "politic",
    "government",
    "law",
    "current event",
    "geopolit",
    "conflict",
    "war",
    "protest",
    "legislation",
    "campaign",
}

TIME_SENSITIVE_KEYWORDS = {
    "today",
    "tonight",
    "current",
    "latest",
    "recent",
    "now",
    "deadline",
    "forecast",
    "schedule",
    "timeline",
    "this week",
    "this month",
    "breaking",
}

RELAXED_SAFETY_SETTINGS = [
    genai_types.SafetySetting(
        category=genai_types.HarmCategory.HARM_CATEGORY_CIVIC_INTEGRITY,
        threshold=genai_types.HarmBlockThreshold.BLOCK_ONLY_HIGH,
    ),
]


class AssistantError(Exception):
    """Custom exception for assistant-related errors."""
    pass


def ask_gemini(prompt: str, *, model: str = DEFAULT_MODEL) -> str:
    """
    Send a prompt to Gemini and return the response text.

    Raises AssistantError on failure.
    """
    logger.info("ask_gemini called with prompt length=%d", len(prompt))

    if not prompt.strip():
        raise AssistantError("Prompt is empty. Please enter a question or request.")

    contextual_prompt, context_meta = _build_contextual_prompt(prompt)
    logger.info(
        "Prompt context: sensitive=%s research=%s time_sensitive=%s",
        context_meta["is_sensitive"],
        context_meta["is_research"],
        context_meta["is_time_sensitive"],
    )

    try:
        response = client.models.generate_content(
            model=model,
            contents=contextual_prompt,
            config=genai_types.GenerateContentConfig(
                temperature=0.5,
                max_output_tokens=1024,
                safety_settings=RELAXED_SAFETY_SETTINGS,
            ),
        )

        # Robustly extract text: prefer response.text, otherwise fall back to
        # joining candidate parts (covers some safety-blocked or streaming cases).
        text = getattr(response, "text", None)
        if not text:
            candidates = getattr(response, "candidates", []) or []
            parts = []
            for cand in candidates:
                content = getattr(cand, "content", None)
                if not content:
                    continue
                for part in getattr(content, "parts", []) or []:
                    if hasattr(part, "text") and part.text:
                        parts.append(part.text)
            if parts:
                text = "\n".join(parts).strip()

        if not text:
            logger.warning("Gemini returned no text field.")
            raise AssistantError("The assistant didn't return any text. Try again.")

        logger.info("ask_gemini succeeded")
        return text

    except AssistantError:
        raise

    except Exception as e:
        logger.exception("Unexpected error calling Gemini API: %s", e)
        raise AssistantError(
            "Something went wrong talking to the AI backend. "
            "Check logs for details and try again."
        ) from e


def _analyze_prompt(prompt: str) -> Tuple[bool, bool, bool]:
    """
    Returns a (is_sensitive, is_research, is_time_sensitive) tuple for heuristics.
    """
    lowered = prompt.lower()
    is_sensitive = any(token in lowered for token in SENSITIVE_KEYWORDS)
    is_research = any(token in lowered for token in RESEARCH_KEYWORDS)
    is_time_sensitive = any(token in lowered for token in TIME_SENSITIVE_KEYWORDS)
    return is_sensitive, is_research, is_time_sensitive


def _build_contextual_prompt(prompt: str):
    """
    Prepend lightweight context so the model understands user intent.
    Returns the augmented prompt along with metadata for logging.
    """
    is_sensitive, is_research, is_time_sensitive = _analyze_prompt(prompt)
    current_date, current_time = _current_datetime_strings()
    context_lines = [
        BASE_SYSTEM_PROMPT_TEMPLATE.format(
            current_date=current_date,
            current_time=current_time,
        )
    ]

    if is_sensitive and is_research:
        context_lines.append(
            "Context: The user is examining a sensitive or political subject "
            "purely for neutral/academic research."
        )
    elif is_sensitive:
        context_lines.append(
            "Context: This touches on sensitive civic topics. Provide factual, "
            "balanced analysis and avoid persuasion."
        )
    elif is_research:
        context_lines.append(
            "Context: Treat the request as a scholarly or technical research task."
        )
    if is_time_sensitive:
        context_lines.append(
            "Context: The user stressed timeliness. Use the stated current date "
            f"{current_date} and time {current_time} when framing your answer."
        )
    if EXTRA_ASSISTANT_CONTEXT:
        context_lines.append(EXTRA_ASSISTANT_CONTEXT)

    context_lines.append("User prompt:")
    context_lines.append(prompt.strip())
    context_lines.append("")
    context_lines.append("Assistant response:")

    contextual_prompt = "\n".join(context_lines)

    return contextual_prompt, {
        "is_sensitive": is_sensitive,
        "is_research": is_research,
        "is_time_sensitive": is_time_sensitive,
    }


def _current_datetime_strings() -> Tuple[str, str]:
    """
    Returns formatted (date, time) strings using the local timezone to provide
    Gemini with concrete temporal context every call.
    """
    now = datetime.now().astimezone()
    date_str = now.strftime("%B %d, %Y")
    time_str = now.strftime("%H:%M %Z")
    return date_str, time_str
