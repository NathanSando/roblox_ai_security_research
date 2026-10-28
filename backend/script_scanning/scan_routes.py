import asyncio
import logging
import uuid
from threading import Thread, Lock

from flask import Blueprint, request
from backend.ai_client import ollama_review

logger = logging.getLogger(__name__)
scan_bp = Blueprint("script_scanning", __name__)

scans = {}
scan_lock = Lock()
# Separate from stored results so DELETE cannot release a running AI request.
active_scan = None


@scan_bp.route("/scan", methods=["POST"])
def scan_scripts():
    global active_scan
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return {"error": "Expected a JSON object."}, 400
    scripts = data.get("scripts")
    if not isinstance(scripts, list):
        return {"error": "'scripts' must be a list."}, 400

    scan_id = str(uuid.uuid4())
    job = {"id": scan_id, "cancelled": False, "loop": None, "task": None}
    with scan_lock:
        if active_scan is not None:
            return {"error": "A scan is running or stopping. Please wait before starting another."}, 409
        active_scan = job
        scans[scan_id] = {"status": "running"}

    try:
        Thread(target=start_scan, args=(scripts, job), daemon=True).start()
    except Exception:
        with scan_lock:
            active_scan = None
            scans.pop(scan_id, None)
        logger.exception("Could not start scan worker")
        return {"error": "Could not start scan worker."}, 500
    return {"scan_id": scan_id}, 202


async def run_review(scripts, job):
    with scan_lock:
        # Cancellation can arrive before the worker starts its event loop.
        if job["cancelled"]:
            raise asyncio.CancelledError
        job["loop"] = asyncio.get_running_loop()
        job["task"] = asyncio.create_task(ollama_review(scripts))
    try:
        return await job["task"]
    finally:
        with scan_lock:
            job["loop"] = None
            job["task"] = None


def start_scan(scripts, job):
    global active_scan
    scan_id = job["id"]
    try:
        report = asyncio.run(run_review(scripts, job))
        result = {"status": "completed", "report": report}
    except asyncio.CancelledError:
        result = {"status": "cancelled"}
    except Exception as error:
        logger.exception("Scan %s failed", scan_id)
        result = {"status": "failed", "error": str(error)}
    finally:
        # asyncio.run finishes stream/client and loop cleanup before releasing the slot.
        with scan_lock:
            if active_scan is job:
                active_scan = None

    with scan_lock:
        scan = scans.get(scan_id)
        if scan is not None and scan["status"] == "running":
            scans[scan_id] = result


@scan_bp.route("/scan/<scan_id>/cancel", methods=["POST"])
def cancel_scan(scan_id):
    with scan_lock:
        scan = scans.get(scan_id)
        if scan is None:
            return {"error": "No scan found with given ID."}, 404
        if scan["status"] == "cancelled":
            return {"status": "cancelled"}, 200
        if scan["status"] != "running":
            return {"error": "Scan has already finished."}, 409

        scans[scan_id] = {"status": "cancelled"}
        if active_scan is not None and active_scan["id"] == scan_id:
            active_scan["cancelled"] = True
            if active_scan["task"] is not None:
                active_scan["loop"].call_soon_threadsafe(active_scan["task"].cancel)
        return {"status": "cancelled"}, 200


@scan_bp.route("/scan/<scan_id>", methods=["GET"])
def check_scan(scan_id):
    with scan_lock:
        scan = scans.get(scan_id)
        if scan is None:
            return {"error": "No scan found with given ID."}, 404
        return scan


@scan_bp.route("/scan/<scan_id>", methods=["DELETE"])
def remove_scan(scan_id):
    with scan_lock:
        scan = scans.get(scan_id)
        if scan is None:
            return {"error": "No scan found with given ID."}, 404
        if scan["status"] == "running":
            return {"error": "Wait for the scan to finish before removing it."}, 409
        del scans[scan_id]
    return {"message": "Scan removed."}, 200