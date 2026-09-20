# Database models for the application.

from database import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    roblox_id = db.Column(db.BigInteger, unique=True, nullable=True)
    name = db.Column(db.String(100), nullable=False)
    is_admin = db.Column(db.Boolean, default=False, nullable=False)
    is_sus = db.Column(db.Boolean, default=False, nullable = False)