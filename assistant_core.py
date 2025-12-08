import logging
import os

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

if not GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY is not set. Check your .env file.")
    raise RuntimeError("GEMINI_API_KEY environment variable is required.")

# Create a single shared client.
client = genai.Client(api_key=GEMINI_API_KEY)

# Choose a default model – adjust if you want Pro instead of Flash.
DEFAULT_MODEL = "gemini-2.5-flash"


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

    try:
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=genai_types.GenerateContentConfig(
                temperature=0.5,
                max_output_tokens=1024,
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
