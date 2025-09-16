from flask import Blueprint
import os, sys
import subprocess
import shutil
import datetime, time

import os
from flask import Flask
from flask_socketio import SocketIO
from flask_sqlalchemy import SQLAlchemy

# <!-- [SS-2]: Global Variables ----->
socketio = SocketIO()
db = SQLAlchemy()
_dir = os.path.dirname(os.path.abspath(__file__))

# <!-- [SS-3]: Helper Functions ----->

# <!-- [SS-4]: Functions ----->
def create_app():
    '''Create and configure the Flask application instance.'''
    app = Flask(__name__, static_folder='static', template_folder='templates')
    app.config['SUPPORTED_LANGUAGES'] = ['en', 'ja', 'sp', 'de']
    app.config['DEFAULT_LANGUAGE'] = 'en'
    app.config['SECRET_KEY'] = '直腸暴行海賊'
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{_dir}/database.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SESSION_COOKIE_SECURE'] = False  # True in production
    app.config['SESSION_COOKIE_HTTPONLY'] = True
    app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
    app.config['SQLALCHEMY_ECHO'] = False  # Set to True for debugging SQL queries
    app.config['DEBUG'] = True  # Set to False in production
    app.config['TESTING'] = True
    app.config['PERMANENT_SESSION_LIFETIME'] = 3600  # seconds
    app.config['SESSION_REFRESH_EACH_REQUEST'] = True
    app.config['JSON_SORT_KEYS'] = True
    app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True
    app.config['PREFERRED_URL_SCHEME'] = 'https'

    db.init_app(app)

# <!-- Register & Config bp's ----->
    from bp.main import main as main_bp
    app.register_blueprint(main_bp)

    socketio.init_app(app, cors_allowed_origins="*")
    return app, socketio
