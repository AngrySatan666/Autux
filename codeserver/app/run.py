# <!-- [SS-1]: Imports ----->
from app import create_app, socketio, db
import os, argparse

# <!-- [SS-2]: Global Variables ----->
_dir = _dir = os.path.dirname(os.path.abspath(__file__))
app, socketio = create_app()

# <!-- [SS-3]: Helper Functions ----->
from models import *
with app.app_context():
    db.create_all()

# <!-- [SS-4]: Functions ----->

# <!-- [SS-5]: Runnit ----->
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run the Flask Application.')
    parser.add_argument('--port', type=int, default=5000, help=['Set the Port Number', 'Default 5000'])
    parser.add_argument('--debug', type=str, default=True, help=['Enable Debug Mode', 'Default True'])
    args = parser.parse_args()
    socketio.run(app, host='127.0.0.1', port=args.port, debug=args.debug)
