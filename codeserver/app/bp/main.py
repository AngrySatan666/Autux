from flask import Blueprint, current_app, send_from_directory, render_template, redirect, url_for, request
from datetime import datetime
import os

users = [
    {"angry": "tfukgobx"},
    {"creecrush": "pyslut"}
]

main = Blueprint('main', __name__)

@main.route('/favicon.ico', methods=['GET'])
def favicon():
    return send_from_directory(os.path.join(current_app.root_path, 'static', 'img'), 'favicon.ico')

@main.route('/')
def index ():
    langs = current_app.config['SUPPORTED_LANGUAGES']
    lang = request.accept_languages.best_match(langs)
    return redirect(url_for('main.local_index', lang=lang or current_app.config['DEFAULT_LANGUAGE']))

@main.route('/<lang>/')
def local_index(lang):
    if lang not in current_app.config['SUPPORTED_LANGUAGES']:
        lang = current_app.config['DEFAULT_LANGUAGE']
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return render_template(f'{lang}/landing.html', current_time=current_time)

@main.route('/<lang>/code/user=<usr>&key=<key>', methods=['GET'])
def code_server(usr, key):
    if usr in [list(u.keys())[0] for u in users] and key in [list(u.values())[0] for u in users]:
        return render_template('code.html', usr=usr, key=key)
