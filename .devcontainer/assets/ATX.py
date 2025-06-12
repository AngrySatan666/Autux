#!/usr/bin/env python3

"""Autux - ADB Automation Toolkit for Termux
This script provides a set of tools to automate interactions with an Android device using ADB (Android Debug Bridge).
It allows users to perform actions such as tapping, swiping, sending text input, taking screenshots, recording the screen, launching apps, and more.
It is designed to be run in a Termux environment on Android devices.
"""
## <!-- [SS-0]: MetaData ----->
Version = '0.0.59'
Date = '5.29.25'

## <!-- [SS-1]: Imports ----->
import time
import argparse
import subprocess
import os
import re
from datetime import datetime

## <!-- [SS-2]: Variable Setting ----->
VENV = os.environ.get("VENV")
FPy = os.environ.get("FPy")
FBash = os.environ.get("FBash")
PX = os.environ.get("PX")
LX = os.environ.get("LX")
adbsh = os.environ.get("adbsh", "None")
_dir = os.path.dirname(os.path.abspath("__file__"))
sav_dir = None

## <!-- [SS-3]: Helper Functions ---->
def DIR (x=None) :
    """Set the save directory based on the current working directory.
    """
    if x is None :
        if "data/data/com.termux" in _dir :
            sav_dir = f"{PX}"
        elif "sdcard" in _dir :
            sav_dir = f"{FPy}"
        else :
            sav_dir = ""
    if x == "LX" :
        sav_dir = f"{LX}"
    if x == "PX" :
        sav_dir = f"{PX}"
    if x == "dir" :
        sav_dir = f"{_dir}"
    return sav_dir

def check_adb() :
    """Check if ADB is installed and accessible."""
    test = subprocess.run(["adb", "version"], check=True, capture_output=True, text=True)
    if "Android" not in test.stdout.splitlines()[0] :
        print("[WARN]: ADB is not installed")
        print("[WARN]: Installing")
        subprocess.run(["pkg", "install", "android-tools", "-y"], check=True)
    if adbsh == "None" :
        try:
            result = subprocess.run(["adb", "tcpip", "5555"], capture_output=True, text=True, check=True)
            if "restarting" in result.stdout.splitlines()[0] :
                os.environ["adbsh"] = "1"
                print("ADB Sees the Device")
            else:
                os.environ["adbsh"] = "0"
                print("[WARN]: ADB DOES NOT SEE THE DEVICE")
                print ("[WARN]: Attempting to Locally Repair ADB")
                subprocess.run(["adb", "kill-server"], check=True)
                subprocess.run(["adb", "disconnect"], check=True)
                subprocess.run(["adb", ""], check=True)
        except subprocess.CalledProcessError:
            os.environ["adbsh"] = "0"

def exe (cmd) :
    """Execute a shell command and print the output.
    Args:
        cmd (list): The command to execute as a list of strings.
    """
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print ("Output: ", result.stdout.strip())
    except subprocess.CalledProcessError as e :
        print ("Error: ", e.stderr.strip())

## <!-- [SS-4]: Autux Functions ----->
def tap (x, y) :
    """Simulate a tap on the device screen at the specified coordinates."""
    exe (cmd=["adb", "shell", "input", "tap", str(x), str(y)])

def hold (x, y, d) :
    """Simulate a hold gesture on the device screen at the specified coordinates for a given duration.
    Args:
        x (int): The x-coordinate of the tap location.
        y (int): The y-coordinate of the tap location.
        d (int): The duration to hold the tap in milliseconds.
    """
    exe (cmd=["adb", "shell", "input", "touchscreen", "swipe", str(x), str(y), str(x), str(y), str(d)])

def swipe (x1, y1, x2, y2, duration) :
    """Simulate a swipe gesture on the device screen from one point to another."""
    exe (cmd=["adb", "shell", "input", "touchscreen", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration)])

def txt (x) :
    """Simulate text input on the device.
    This function sends the specified text to the device's input system.
    Args:
        x (str): The text to input.
    """
    exe (cmd=["adb", "shell", "input", "text", x.replace(" ", "%s")])

def notify (title, content) :
    """Send a notification to the Termux app.
    Args:
        title (str): The title of the notification.
        content (str): The content of the notification.
    """
    exe (cmd=["termux-notification", "--title", title, "--content", content])

def scr (file) :
    """Capture a screenshot of the device screen.
    This function saves the screenshot to the specified file in the /sdcard directory.
    The file will be saved in PNG format.
    Args:
        file (str): The name of the file to save the screenshot.
    """
    exe (cmd=["echo", "-n", ">", f"{sav_dir}/{file}.png"])
    exe (cmd=["adb", "shell", "screencap", f"{sav_dir}/{file}.png"])

def rec (file) :
    """Start screen recording on the device.
    Args:
        file (str): The name of the file to save the screen recording.
    """
    exe (cmd=["echo", "-n", ">", f"{sav_dir}/{file}.mp4"])
    exe (cmd=["adb", "shell", "screenrecord", f"{sav_dir}/{file}.mp4"])

def norec () :
    """Stop screen recording on the device.
    """
    exe (cmd=["adb", "shell", "pkill", "-l", "INT", "screenrecord"])

def app (pkg) :
    """Launch an app on the device by its package name.
    This function uses the Android Debug Bridge (ADB) to start the specified app.
    The package name should be in the format "com.example.app".
    Args:
        pkg (str): The package name of the app to launch.
    """
    exe (cmd=["adb", "shell", "monkey", "-p", f"{pkg}", "1"])

def noapp (pkg) :
    """Stop an app on the device by its package name.
    Args:
        pkg (str): The package name of the app to stop.
    """
    exe (cmd=["adb", "shell", "am", "force-stop", f"{pkg}"])

def listcom () :
    """List all installed apps on the device.
    """
    exe (cmd=["adb", "shell", "pm", "list", "packages"])

## <!-- [SS-5]: Major Functions ----->
def start_screenrecord (output_file) :
    """Start screen recording on the device.
    Args:
        output_file (str): The name of the output file.
    Returns:
        subprocess.Popen: The process object for the screen recording.
    """
    exe (cmd=["echo", "-n", ">", f"{sav_dir}/{output_file}"])
    return subprocess.Popen(["adb", "shell", "screenrecord", f"{sav_dir}/{output_file}"])

def record_taps (label=None, hold_threshold=0.5) :
    """
    Record tap gestures on the device screen and save them to a log file and video file.
    Args:
        label (str, optional): The label for the log files. Defaults to None.
        hold_threshold (float, optional): The duration (in seconds) to consider a tap as a hold. Defaults to 0.5.
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = os.path.join(sav_dir, label) if label else sav_dir
    log_file = f"{base_name}tap_log{timestamp}.txt"
    video_file = f"{base_name}video_log{timestamp}.mp4"
    exe (cmd=["echo", "-n", ">", f"{log_file}"])
    exe (cmd=["echo", "-n", ">", f"{video_file}"])
    print (f"Recording to :\n  Log: {log_file}\n  Video: {video_file}\n  Press Ctrl+C to stop.")
    pattern_x = re.compile(r'ABS_MT_POSITION_X\s+(\w+)')
    pattern_y = re.compile(r'ABS_MT_POSITION_Y\s+(\w+)')
    screen_proc = start_screenrecord (video_file)
    with open(log_file, "w", encoding="utf-8") as f :
        proc = subprocess.Popen(["adb", "shell","getevent", "-lt"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        x = y = None
        gesture_points = []
        touch_start_time = None
        try :
            for line in proc.stdout :
                if 'ABS_MT_POSITION_X' in line :
                    match = pattern_x.search(line)
                    if match :
                        x = int(match.group(1), 16)
                elif 'ABS_MT_POSITION_Y' in line :
                    match = pattern_y.search(line)
                    if match :
                        y = int(match.group(1), 16)
                elif 'BTN_TOUCH' in line and 'DOWN' in line :
                    touch_start_time = time.time()
                    gesture_points = []
                    if x is not None and y is not None :
                        gesture_points.append((x,y))
                elif 'EV_SYN' in line and touch_start_time is not None :
                    if x is not None and y is not None :
                        gesture_points.append((x,y))
                elif 'BTN_TOUCH' in line and 'UP' in line :
                    duration = time.time() - touch_start_time if touch_start_time else 0
                    gesture_type = "Tap"
                    if gesture_points:
                        x0, y0 = gesture_points[0]
                        x1, y1 = gesture_points[-1]
                        dist = ((x1 - x0)**2 + (y1 - y0)**2) ** 0.5
                    else:
                        dist = 0
                    if duration >= hold_threshold and dist <= 10:
                        gesture_type = "Hold"
                    elif dist > 10:
                        gesture_type = "Swipe"
                    timestamp_now = datetime.now().isoformat()
                    log_line = f"[{timestamp_now}] {gesture_type} ({duration:.2f}s): {gesture_points}\n"
                    print (log_line.strip())
                    f.write(log_line)
                    f.flush()
                    x = y = None
                    gesture_points = []
                    touch_start_time = None
        except KeyboardInterrupt :
            print ("Stopping Recording...")
            proc.terminate()
            screen_proc.terminate()
            print ("Pulling to Local Storage")
            exe (cmd=["mv", f"{_dir}/{log_file}", f"{FPy}/{log_file}"])
            exe (cmd=["mv", f"{_dir}/{video_file}", f"{FPy}/{video_file}"])

## <!-- [SS-6]: Runnit ----->
def main () :
    """
    Main function to parse command line arguments and execute corresponding ADB commands.
    """
    parser = argparse.ArgumentParser(description="Autux - ADB Automation Toolkit for Termux")
    parser.add_argument ("--tap", nargs=2, metavar=("X", "Y"), type=int, help="Tap at Screen Co-Ordinates")
    parser.add_argument ("--swipe", nargs=5, metavar=("X1", "Y1", "X2", "Y2", "DURATION"), type=int,help="Swipe from one point to another")
    parser.add_argument ("--txt", type=str, metavar="TEXT", help="Input Text")
    parser.add_argument ("--notify", nargs=2, metavar=("TITLE", "CONTENT"), help="Send Termux Notification")
    parser.add_argument("--scr", metavar="FILENAME", help="Screenshot to /sdcard/FILENAME.png")
    parser.add_argument("--rec", metavar="FILENAME", help="Record screen to /sdcard/FILENAME.mp4")
    parser.add_argument("--norec", action="store_true", help="Stop screen recording")
    parser.add_argument("--app", metavar="PKG", help="Launch app by package name")
    parser.add_argument("--noapp", metavar="PKG", help="Force-stop app by package name")
    parser.add_argument("--record-taps", action="store_true", help="Start tap/screen recording session")
    parser.add_argument("--label", metavar="LABEL", help="Optional label for record-taps")
    parser.add_argument("--listcom", action="store_true", help="List all installed apps to the console")
    args = parser.parse_args()
    if args.tap:
        tap(*args.tap)
    if args.swipe:
        swipe(*args.swipe)
    if args.txt:
        txt(args.txt)
    if args.notify:
        notify(*args.notify)
    if args.scr:
        scr(args.scr)
    if args.rec:
        rec(args.rec)
    if args.norec:
        norec()
    if args.app:
        app(args.app)
    if args.noapp:
        noapp(args.noapp)
    if args.record_taps:
        record_taps(label=args.label)
    if args.listcom:
        listcom()
    if not any(vars(args).values()):
        record_taps()

if __name__ == "__main__" :
    DIR(x="dir")
    main ()
