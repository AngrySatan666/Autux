#!/usr/bin/env python3

## <!-- [SS-0]: MetaData ----->
Version = '0.2.6'
Date = '6.17.25'
Dev = 'AngrySatan666'

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
src = '/sdcard/Termux/download/'
sav_dir = None

## <!-- [SS-3]: Helper Functions ----->
def exe (cmd, output=None, popen=None) :
    out = bool(output)
    txt = bool(output)
    try :
        if popen :
            # For tap_rec, we want to return the process object
            return subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        else :
            result = subprocess.run(cmd, capture_output=out, text=txt, check=True)
            if out :
                print ("Output: ", result.stdout.strip())
            return result
    except subprocess.CalledProcessError as e :
        print ("[ERROR]: ", e.stderr.strip() if hasattr(e, "stderr") and e.stderr else str(e))

def ts () :
    now = datetime.now()
    return now.strftime("%Y.%m.%d:%H.%M")

## <!-- [SS-4]: Autux ------>
def tap (x=int, y=int) :
    exe(["adb", "shell", "input", "tap", str(x), str(y)])

def hold (x=int, y=int, d=None) :
    if d is None :
        d = 1000
    exe(["adb", "shell", "input", "touchscreen", "swipe", str(x), str(y), str(x), str(y), str(d)])

def swipe (x1=int, y1=int, x2=int, y2=int, d=None) :
    if d is None :
        d = 250
    exe(["adb", "shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(d)])

def txt (x=str):
    exe(["adb", "shell", "input", "text", x.replace(" ", "%s")])

def notify (t=str, x=str) :
    exe(["termux-notification", "--title", str(t), "--content", str(x)])

def toast (x=str, l=None) :
    if l is not None :
        exe(["termux-toast", "-g", str(l), "-s", str(x)])
    else :
        exe(["termux-toast", "-g", "center", "-s", str(x)])

def cap (x=None) :
    if x :
        fx = os.path.join(src, x)
    else :
        fx = os.path.join(src, ts() + ".png")
    exe(["adb", "shell", "screencap", "-p", str(fx)])

def rec (x=None) :
    if x :
        fx = os.path.join(src, x)
    else :
        fx = os.path.join(src, ts() + ".mp4")
    # For tap_rec, we want to return the process
    return exe(["adb", "shell", "screenrecord", str(fx)], popen=True)

def app (x=str) :
    exe(["adb", "shell", "monkey", "-p", f"{x}", "1"])

def noapp (x=str) :
    exe(["adb", "shell", "am", "force-stop", f"{x}"])

def web (x=str) :
    exe(["termux-open-url", str(x)])

def listcom () :
    exe(["adb", "shell", "pm", "list", "packages"])

def newip () :
    exe(["bash", os.path.join(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"), "bin/session"), "--newip"])

def updatesettings () :
    exe(["bash", os.path.join(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"), "bin/session"), "--updatesettings"])

# <!-- [SS-5]: Major Functions ----->
def tap_rec (label=None, hold_threshold=0.5) :
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(src, f"tap_log{stamp}.txt")
    video_file = os.path.join(src,f"vid_log{stamp}.mp4")
    print (f"Recording to :\n  Log: {log_file}\n  Video: {video_file}\n  Press Ctrl+C to stop.")
    pattern_x = re.compile(r'ABS_MT_POSITION_X\s+(\w+)')
    pattern_y = re.compile(r'ABS_MT_POSITION_Y\s+(\w+)')
    screen_proc = rec(x=video_file)
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
            if screen_proc :
                screen_proc.terminate()

## <!-- [SS-]: Runnit ----->
def main () :
    parser = argparse.ArgumentParser(description="Autux - A simple automation tool for Android devices.")
    parser.add_argument("--tap", nargs=2, type=int, help="Tap at coordinates (x, y).")
    parser.add_argument("--hold", nargs=3, type=int, help="Hold at coordinates (x, y) for duration d (ms).")
    parser.add_argument("--swipe", nargs=4, type=int, help="Swipe from (x1, y1) to (x2, y2) for duration d (ms).")
    parser.add_argument("--txt", nargs=1, type=str, help="Send text input.")
    parser.add_argument("--notify", nargs=2, type=str, help="Send a notification with title and content.")
    parser.add_argument("--toast", nargs=2, type=str, help="Show a toast message with content, and location.")
    parser.add_argument("--cap", action="store_true", help="Capture the screen.")
    parser.add_argument("--rec", type=str, help="Record the screen to a file.")
    parser.add_argument("--app", type=str, help="Launch an app by package name.")
    parser.add_argument("--noapp", type=str, help="Force stop an app by package name.")
    parser.add_argument("--web", type=str, help="Open a URL in the default browser.")
    parser.add_argument("--listcom", action="store_true", help="List all installed packages.")
    parser.add_argument("--newip", action="store_true", help="Get a new IP address.")
    parser.add_argument("--updatesettings", action="store_true", help="Update settings.")
    parser.add_argument("--taprec", action="store_true", help="Record tap gestures and save to a file.")
    parser.add_argument("--version", action="version", version=f"%(prog)s {Version} ({Date}) by {Dev}")
    args = parser.parse_args()
    if args.tap :
        tap(*args.tap)
    elif args.hold :
        hold(*args.hold)
    elif args.swipe :
        swipe(*args.swipe)
    elif args.txt :
        txt(*args.txt)
    elif args.notify :
        notify(*args.notify)
    elif args.toast :
        toast(*args.toast)
    elif args.cap :
        cap()
    elif args.rec :
        rec(args.rec)
    elif args.app :
        app(args.app)
    elif args.noapp :
        noapp(args.noapp)
    elif args.web :
        web(args.web)
    elif args.listcom :
        listcom()
    elif args.newip :
        newip()
    elif args.updatesettings :
        updatesettings()
    elif args.taprec :
        tap_rec()

if __name__ == "__main__":
    main()
