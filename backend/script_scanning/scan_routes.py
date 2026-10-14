from flask import Blueprint, request
from backend.ai_client import ollama_review
from threading import Thread
import logging
import uuid

logger = logging.getLogger(__name__)
scan_bp = Blueprint("script_scanning", __name__)

# Contains all scans occuring.
scans = {}

@scan_bp.route("/scan", methods=["POST"])
def scan_scripts():

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return {"error": "Expected a JSON object."}, 400

    scripts = data.get("scripts")

    if not isinstance(scripts, list):
        return{"error": "'scripts' must be a list."}, 400

    scan_id = str(uuid.uuid4())
    # Change the status of the scan that is indexed by the scan id.
    scans[scan_id] = {"status": "running"}

    # Start the review using the thread.
    Thread(
        target=start_scan,
        args=(scripts, scan_id),
        daemon=True
    ).start()

    # Return the scan id so that Reye can use it.
    return {"scan_id": scan_id}, 202

def start_scan(scripts, scan_id):

    try:
        report = ollama_review(scripts)
    except Exception as error:
        logger.exception("Scan %s failed", scan_id)
        # If it fails change the status and return the error as a string.
        scans[scan_id] = {
            "status": "failed",
            "error": str(error)
        }

    else:
        # If it succeeds then change the status of the scan and return the report.
        scans[scan_id] = {
            "status": "completed",
            "report": report
        }

# This is called with the scan id to check the status.
@scan_bp.route("/scan/<scan_id>", methods=["GET"])
def check_scan(scan_id):

    scan = scans.get(scan_id)

    if scan is None:
        return {"error": "No scan found with given ID."}, 404

    # Get the status of the scan.
    return scan

@scan_bp.route("/scan/<scan_id>", methods=["DELETE"])
def remove_scan(scan_id):

    scan = scans.get(scan_id)

    if scan is None:
        return {"error": "No scan found with given ID."}, 404

    if scan["status"] == "running":
        return {"error": "Wait for the scan to finish before removing it."}, 409

    # Delete the scan from the table.
    del scans[scan_id]
    return {"message": "Scan removed."}, 200