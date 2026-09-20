# Uses database.py and creates the actual application.

from flask import Flask
from analysis_routes import analysis_bp
from database import db
from user_routes import users_bp
from data_import import import_bp

def create_app(config=None):
    app = Flask(__name__)
    app.json.sort_keys = False
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///app.db"
    if config is not None:
        app.config.update(config)

    db.init_app(app)
    # Creates blueprint for different sections of the application.
    app.register_blueprint(users_bp)
    app.register_blueprint(analysis_bp)
    app.register_blueprint(import_bp)

    with app.app_context():
        db.create_all()

    return app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True)
