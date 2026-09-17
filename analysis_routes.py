from pathlib import Path

from flask import Blueprint

from ai_client import ollama_read
from data_export import export_data
from models import User

analysis_bp = Blueprint("analysis", __name__)

# Feed AI data using export data.
@analysis_bp.route("/users/feed", methods=["GET"])
def feed_data():

    # Create the user data file only when it is missing.
    if not Path("user_data.json").exists():
        users = User.query.all()
        data = [{"user": user.name, "id": user.id} for user in users]
        export_data(data)

    # Ask to evalute.
    result = ollama_read(
        "user_data.json",
        "Please evaluate the information and tell me what it means."
    )

    # Print evaluation.
    return {
       "result": result
    }

