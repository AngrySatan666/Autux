import sys, os

## <!-- [SS-1]: Variables -----> ##
_dir = os.path.dirname(os.path.abspath(__file__))
autux_path = os.path.join(_dir, "autux")

## <!-- [SS-2]: Functions -----> ##
def add_dir_and_subdirs(path):
    if path and os.path.isdir(path):
        if path not in sys.path:
            sys.path.append(path)
        for root, dirs, files in os.walk(path):
            for d in dirs:
                subdir = os.path.join(root, d)
                if subdir not in sys.path:
                    sys.path.append(subdir)

## <!-- [SS-3]: Main Script -----> ##
for var, value in os.environ.items():
    add_dir_and_subdirs(value)

if os.path.isdir(autux_path) and autux_path not in sys.path:
    sys.path.insert(0, autux_path)