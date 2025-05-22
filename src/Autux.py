#!/usr/bin/env python3

## <!-- [SS-0]: MetaData ----->
Version = '0.0.9'
Date = '5.20.25'

## <!-- [SS-1]: Imports ----->
import time
import argparse
import subprocess
import os, re
from datetime import datetime

## <!-- [SS-3]: Variables ----->
_dir = os.path.dirname(os.path.abspath(__file__))
VENV = os.environ.get("VENV")
FX = os.environ.get("FPy")

# <!-- [SS-4]: Helper Functions ---->
def exe (cmd) :
    try:
        result = subprocess.run(cmd, capture=True, text=True, check=True)
        print ("Output: ", result.stdout.strip())
    except subprocess.CalledProcessError as e :
        print ("Error: ", e.stderr.strip())

def tap (x, y) :
    exe (cmd=["adb", "shell", "input", "tap", str(x), str(y)])

def swipe (x1, y1, x2, y2, duration) :
    exe (cmd=["adb", "shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(duration)])

def txt (x) :
    exe (cmd=["adb", "shell", "input", "text", x.replace(" ", "%s")])

def notify (title, content) :
    exe (cmd=["termux-notification", "--title", title, "--content", content])

def scr (file) :
    exe (cmd=["adb", "shell", "screencap", f"{_dir}/{file}.png"])

def rec (file) :
    exe (cmd=["adb", "shell", "screenrecord", f"{_dir}/{file}.mp4"])

def norec () :
    exe (cmd=["adb", "shell", "pkill", "-l", "INT", "screenrecord"])

def app (pkg) :
    exe (cmd=["adb", "shell", "monkey", "-p", f"com.{pkg}", "-c", "android.intent.category.LAUNCHER", "1"])

def noapp (pkg) :
    exe (cmd=["adb", "shell", "am", "force-stop", f"com.{pkg}"])

## <!-- [SS-5]: Main Functions ----->
def start_screenrecord (output_file) :
    return subprocess.Popen(["adb", "shell", "screenrecord", f"{_dir}/{output_file}"])

def record_taps (label=None, hold_threshold=0.5) :
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = f"{label}_" if label else ""
    log_file = f"{base_name}tap_log{timestamp}.txt"
    video_file = f"{base_name}video_log{timestamp}.mp4"
    print (f"Recording to :\n  Log: {log_file}\n  Video: {video_file}\n  Press Ctrl+C to stop.")
    pattern_x = re.compile(r'ABS_MT_POSITION_X\s+(\w+)')
    pattern_y = re.compile(r'ABS_MT_POSITION_Y\s+(\w+)')
    screen_proc = start_screenrecord (video_file)
    with open(os.path.join(_dir, log_file), "w") as f :
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
                    if duration >= hold_threshold and len(gesture_points) == 1 :
                        gesture_type = "Hold"
                    elif len(set(gesture_points)) >1 :
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
            exe (cmd=["mv", f"{_dir}/{log_file}", f"{FX}/{log_file}"])
            exe (cmd=["mv", f"{_dir}/{video_file}", f"{FX}/{video_file}"])

## <!-- [SS-6]: Runnit ----->
def main () :
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
    elif not args :
        record_taps()

if __name__ == "__main__" :
    main ()
