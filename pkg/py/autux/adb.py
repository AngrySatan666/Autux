import subprocess
import re

class Autux:
    def __init__(self):
        self.app_map = {}

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

    def start(self):
        """Start adb server and shell, and rebuild app map."""
        subprocess.run(["adb", "start-server"])
        self.build_app_map()
        return self

    def tap(self, x, y):
        """Simulate a tap at (x, y) on the device."""
        subprocess.run(["adb", "shell", "input", "tap", str(x), str(y)])

    def scrsht(self, filename):
        """Take a screenshot and save to the given filename."""
        device_path = f"/sdcard/{filename}"
        subprocess.run(["adb", "shell", "screencap", "-p", device_path])
        subprocess.run(["adb", "pull", device_path, filename])
        subprocess.run(["adb", "shell", "rm", device_path])

    def open_app(self, appname):
        """Open an app by friendly name using adb."""
        pkg = self.app_map.get(appname.lower())
        if not pkg:
            raise ValueError(f"Unknown app name: {appname}")
        subprocess.run(["adb", "shell", "monkey", "-p", pkg, "-c", "android.intent.category.LAUNCHER", "1"])

    def get_main_activity(self, pkg):
        """Try to find the main launcher activity for a package."""
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