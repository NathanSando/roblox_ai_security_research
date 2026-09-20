from flask import Blueprint, request
from database import db
from models import User
import requests

import_bp = Blueprint("data_import", __name__)


def verify_roblox_account(user_id):
    try:
        response = requests.get(
            f"https://users.roblox.com/v1/users/{user_id}", timeout=10
        )
        if response.status_code == 200:
            return True
        elif response.status_code == 404:
            return False
        else:
            print(f"Request received but error occurred: {response.status_code}")
            return None
    except requests.RequestException as e:
        print(f"An error occurred: {e}")
        return None


# Returns None if the Roblox ID is already in the database.
def add_user(roblox_id, name):
    if User.query.filter_by(roblox_id=roblox_id).first():
        return None

    user = User(roblox_id=roblox_id, name=name)
    db.session.add(user)
    db.session.commit()
    return user


@import_bp.route("/import", methods=["POST"])
def import_data():
    data = request.get_json()
    if isinstance(data, dict):
        data = [data]
    if not isinstance(data, list):
        return {"error": "Expected a list of users."}, 400

    added = []
    for entry in data:
        if not isinstance(entry, dict):
            continue

        roblox_id = entry.get("roblox_id")
        name = entry.get("name")

        if type(roblox_id) is not int or roblox_id <= 0:
            continue

        if verify_roblox_account(roblox_id) is not True:
            continue

        user = add_user(roblox_id)
        if user:
            added.append({"roblox_id": user.roblox_id, "name": user.name})

    return {"added": added}, 200
