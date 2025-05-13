import sys
from autux.adb import Autux

def main():
    autux = Autux().start()

    if len(sys.argv) < 2:
        print("Usage:")
        print("  autux --start")
        print("  autux --tap X Y")
        print("  autux --scrsht filename")
        print("  autux --open_app friendly_app_name")
        print("  autux --browser_open browser_friendly_name url")
        print("  autux --browser_close browser_friendly_name")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "--start":
        autux.start()
    elif cmd == "--tap" and len(sys.argv) == 4:
        autux.tap(int(sys.argv[2]), int(sys.argv[3]))
    elif cmd == "--scrsht" and len(sys.argv) == 3:
        autux.scrsht(sys.argv[2])
    elif cmd == "--open_app" and len(sys.argv) == 3:
        autux.open_app(sys.argv[2])
    elif cmd == "--browser_open" and len(sys.argv) == 4:
        autux.browser(sys.argv[2]).open(sys.argv[3])
    elif cmd == "--browser_close" and len(sys.argv) == 3:
        autux.browser(sys.argv[2]).close()
    else:
        print("Invalid command or arguments.")
        sys.exit(1)