#!/usr/bin/env python3

## <!-- [SS-0]: MetaData ----->
Version = '0.2.59'
Date = '6.10.25'
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
sav_dir = None

## <!-- [SS-3]: Helper Functions ----->
def exe (cmd, output=None, popen=None) :
    if output is True :
        out =  True
        txt = True
    else :
        out = False
        txt = False
    try :
        if popen is True :
            result = subprocess.Popen(cmd, capture_output=out, text=txt, check=True)
        else :
            result = subprocess.run(cmd, capture_output=out, text=txt, check=True)
            print ("Output: ", result.stdout.strip())
    except subprocess.CalledProcessError as e :
        print ("[ERROR]: ", e.stderr.strip())

## <!-- [SS-4]: Autux ------>
def tap (x=int, y=int) :
    if not isinstance(x, int) or not isinstance(y, int) :
        print ("[ERROR]: Coordinates must be integers.")
        return
    cmd = ["adb", "shell", "input", "tap", str(x), str(y)]
    exe(cmd)

def hold (x=int, y=int, d=None) :
    if not isinstance(x, int) or not isinstance(y, int) :
        print ("[ERROR]: Coordinates must be integers.")
        return
    if d is None :
        d = 1000
    cmd = ["adb", "shell", "input", "touchscreen", "swipe", str(x), str(y), str(x), str(y), str(d)]
    exe(cmd)

def swipe (x1=int, y1=int, x2=int, y2=int, d=None) :
    if not isinstance(x1, int) or not isinstance(y1, int) or not isinstance(x2, int) or not isinstance(y2, int) :
        print ("[ERROR]: Coordinates must be integers.")
        return
    if d is None :
        d = 250
    cmd = ["adb", "shell", "input", "swipe", str(x1), str(y1), str(x2), str(y2), str(d)]
    exe(cmd)

def txt (x=str):
    cmd = ["adb", "shell", "input", "text", x.replace(" ", "%s")]
    exe(cmd)

def cap () :
    cmd = ["adb", "shell", "screencap", "-p"]
    exe(cmd)

## <!-- [SS-]: Runnit ----->
def main () :
    parser = argparse.ArgumentParser(description="Autux - A simple automation tool for Android devices.")
    parser.add_argument("--tap", nargs=2, type=int, help="Tap at coordinates (x, y).")
    parser.add_argument("--hold", nargs=3, type=int, help="Hold at coordinates (x, y) for duration d (ms).")
    parser.add_argument("--swipe", nargs=4, type=int, help="Swipe from (x1, y1) to (x2, y2) for duration d (ms).")
    parser.add_argument("--version", action="version", version=f"%(prog)s {Version} ({Date}) by {Dev}")
    args = parser.parse_args()

    if args.tap :
        tap(*args.tap)
    elif args.hold :
        hold(*args.hold)
    elif args.swipe :
        swipe(*args.swipe)
    elif args.version :
        print(f"Autux - A simple automation tool for Android devices.\nVersion: {Version}\nDate: {Date}\nDeveloper: {Dev}")
