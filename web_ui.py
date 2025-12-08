import logging
import os

from flask import Flask, render_template, request
from dotenv import load_dotenv

from assistant_core import ask_gemini, AssistantError

load_dotenv()

app = Flask(__name__)

logger = logging.getLogger("web_ui")
logger.setLevel(logging.INFO)
_console = logging.StreamHandler()
_console.setFormatter(logging.Formatter(
    "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s"
))
logger.addHandler(_console)


@app.route("/", methods=["GET"])
def index():
    return render_template("index.html")


@app.route("/ask", methods=["POST"])
def ask():
    data = request.get_json(silent=True) or {}
    prompt = data.get("prompt", "")
    logger.info("/ask received prompt length=%d", len(prompt))

    try:
        answer = ask_gemini(prompt)
        return {"response": answer}
    except AssistantError as e:
        logger.warning("AssistantError: %s", e)
        return {"error": str(e)}, 400
    except Exception as e:
        logger.exception("Unhandled exception in /ask: %s", e)
        return {
            "error": "An unexpected error occurred while processing your request."
        }, 500


if __name__ == "__main__":
    debug_flag = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    app.run(host="127.0.0.1", port=5000, debug=debug_flag)
