# HTTP endpoints for creating, viewing, and deleting users.

from flask import Blueprint, request

from database import db
from models import User

users_bp = Blueprint("users", __name__)

# Prints out all users and their information.
@users_bp.route("/users")
def get_users():
    users = User.query.all()
    return {
        "users": [
            {
                "name": user.name,
                "id": user.id,
                "is_admin": user.is_admin,
                "is_sus": user.is_sus
            }
            for user in users
        ]
    }

# Adds a user to the database.
@users_bp.route("/users", methods=["POST"])
def add_user():

    data = request.get_json(silent=True)
    name = data.get("name")

    if not name:
        return {"error": "Name is missing"}, 400

    user = User(name=name)

    db.session.add(user)
    db.session.commit()

    users = User.query.all()

    return {
        "message": "User created successfully! Here is the current user list:",
        "user": [
            {
                "name": user.name,
                "id": user.id,
                "is_admin": user.is_admin,
                "is_sus": user.is_sus
            }
            for user in users
        ]
    }, 201

# Deletes a user from the database.
@users_bp.route("/users", methods=["DELETE"])
def delete_user():
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or data.get("id") is None:
        return {"error": "ID is missing."}, 400

    user_id = data["id"]

    if type(user_id) is not int or user_id <= 0:
        return {"error": "ID must be a positive integer."}, 400

    user = db.session.get(User, user_id)
    if not user:
        return {"error": "User is missing or does not exist."}, 404

    db.session.delete(user)
    db.session.commit()

    users = User.query.all()

    return {
        "message": "User removed successfully! Here is the current user list:",
        "users": [
            {
                "user": user.name,
                "id": user.id
            }
            for user in users
        ]
    }, 200

# Marks player as an admin.
@users_bp.route("/users/admin", methods=["POST"])
def add_admin():
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or data.get("id") is None:
        return {"error": "ID is missing."}, 400

    user_id = data["id"]

    if type(user_id) is not int or user_id <= 0:
        return {"error": "ID must be a positive integer."}, 400

    user = db.session.get(User, user_id)
    if not user:
        return {"error": "User is missing or does not exist."}, 404

    user.is_admin = True
    db.session.commit()

    return {
        "message": "User successfully given admin permissions.",
        "user": [
            {
                "user": user.name,
                "id": user.id,
                "is_admin": user.is_admin
            }
        ]
    }, 200

# Marks player as suspicious.
@users_bp.route("/users/sus", methods=["POST"])
def mark_sus():
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or data.get("id") is None:
        return {"error": "ID is missing."}, 400

    user_id = data["id"]

    if type(user_id) is not int or user_id <= 0:
        return {"error": "ID must be a positive integer."}, 400

    user = db.session.get(User, user_id)
    if not user:
        return {"error": "User is missing or does not exist."}, 404

    user.is_sus = True
    db.session.commit()

    return {
        "message": "User successfully marked as suspicious.",
        "user": {
            "name": user.name,
            "id": user.id,
            "is_sus": user.is_sus
        },
    }, 200
