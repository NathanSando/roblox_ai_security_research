from flask import Blueprint, request
from models import User

import_bp = Blueprint("data_import", __name__)

@import_bp.route("/import", methods=["POST"])
def import_data():
    if not request.is_json:
        return {"error": "Expected JSON"}, 415

    data = request.get_json()

    # Validate JSON structure and values.
    if not isinstance(data, dict):
        return {"error": "Expected JSON object."}

    roblox_id = data.get("roblox_id")

    if roblox_id is None:
        return {"error": "Expected Roblox ID."}, 400

    if type(roblox_id) is not int or roblox_id <= 0:
        return {"error": "Invalid Roblox ID"}, 400

    # Check if duplicate, account exists, fields, and permissions.
    users = User.query.all()
    # Might have to rework the add user function to not be in a route.

    
    print(data)

    return {"message": "Message received", "data": data}, 200