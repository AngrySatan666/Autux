import subprocess
import re, os

## <!-- [SS-1]: Variables -----> ##
_dir = os.path.dirname(os.path.abspath(__file__))

## <!-- [SS-2]: Autux Core Class -----> ##
class Autux:
    def __init__(self):
        self.app_map = {}

## <!-- [SS-2.1]: Helper Functions -----> ##
    def build_app_map(self):
        self.app_map = {}
        pkgs = subprocess.check_output(
            ["adb", "shell", "pm", "list", "packages"], text=True
        ).splitlines()
        for pkg_line in pkgs:
            pkg = pkg_line.replace("package:", "").strip()
            try:
                label_out = subprocess.check_output(
                    ["adb", "shell", "dumpsys", "package", pkg], text=True, errors="ignore"
                )
                match = re.search(r'application-label:(.*)', label_out)
                if match:
                    label = match.group(1).strip().lower()
                    self.app_map[label] = pkg
            except Exception:
                continue

    def get_main_activity(self, pkg):
        try:
            out = subprocess.check_output(
                ["adb", "shell", "cmd", "package", "resolve-activity", "--brief", pkg],
                text=True
            )
            parts = out.strip().split()
            if len(parts) >= 2 and "/" in parts[1]:
                return parts[1]
        except Exception:
            pass
        return f"{pkg}/.MainActivity"

## <!-- [SS-2.2]: Automation Functions -----> ##
    def start(self):
        subprocess.run(["adb", "start-server"])
        self.build_app_map()
        return self

    def tap(self, x, y):
        subprocess.run(["adb", "shell", "input", "tap", str(x), str(y)])

    def scrsht(self, filename):
        device_path = os.path.join(_dir, filename)
        subprocess.run(["adb", "shell", "screencap", "-p", device_path])
        subprocess.run(["adb", "pull", device_path, filename])
        subprocess.run(["adb", "shell", "rm", device_path])

    def open_app(self, appname):
        pkg = self.app_map.get(appname.lower())
        if not pkg:
            raise ValueError(f"Unknown app name: {appname}")
        subprocess.run(["adb", "shell", "monkey", "-p", pkg, "-c", "android.intent.category.LAUNCHER", "1"])

## <!-- [SS-2.3]: Browser Control Functions -----> ##
    class BrowserController:
        def __init__(self, adb_instance, browser_friendly_name):
            pkg = adb_instance.app_map.get(browser_friendly_name.lower())
            if not pkg:
                raise ValueError(f"Unknown browser name: {browser_friendly_name}")
            self.browser_pkg = pkg
            self.main_activity = adb_instance.get_main_activity(pkg)
            self.adb_instance = adb_instance

        def open(self, url):
            subprocess.run([
                "adb", "shell", "am", "start", "-n",
                self.main_activity,
                "-a", "android.intent.action.VIEW",
                "-d", url
            ])

        def close(self):
            subprocess.run(["adb", "shell", "am", "force-stop", self.browser_pkg])

    def browser(self, friendly_name):
        return self.BrowserController(self, friendly_name)

## <!-- [SS-3]: CLI Functions -----> ##
def main():
    import sys
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

if __name__ == "__main__":
    main()