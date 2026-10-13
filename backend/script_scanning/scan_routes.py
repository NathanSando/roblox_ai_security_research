from flask import Blueprint, request
from backend.ai_client import ollama_review

scan_bp = Blueprint("script_scanning", __name__)

@scan_bp.route("/scan", methods=["POST"])
def scan_scripts():

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return {"error": "Expected a JSON object."}, 400

    scripts = data.get("scripts")

    if not isinstance(scripts, list):
        return{"error": "'scripts' must be a list."}, 400

    try:
        report = ollama_review(scripts)
    except ValueError as error:
        return {"error": str(error)}, 502

    return report
