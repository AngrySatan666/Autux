
# ADB + Python Integration Cheat Sheet

---

## ADB Shell Commands Cheat Sheet

| Purpose               | Command                                                                 |
|----------------------|-------------------------------------------------------------------------|
| Tap Screen           | `adb shell input tap X Y`                                               |
| Swipe Screen         | `adb shell input swipe X1 Y1 X2 Y2 [duration_ms]`                       |
| Input Text           | `adb shell input text 'hello%sworld'`                                   |
| Send Key Event       | `adb shell input keyevent KEYCODE` (e.g., `KEYCODE_HOME`)               |
| Take Screenshot      | `adb shell screencap /sdcard/screen.png`                                |
| Record Screen        | `adb shell screenrecord /sdcard/video.mp4`                              |
| List Installed Apps  | `adb shell pm list packages`                                            |
| Start App Activity   | `adb shell am start -n com.package/.Activity`                           |
| Force Stop App       | `adb shell am force-stop com.package`                                   |
| Post Notification    | `adb shell cmd notification post -S bigtext -t "Title" tag "Message"`   |

---

## Python: Run ADB Shell Commands

| Purpose                     | Python Code Snippet                                                                                                  |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------|
| **Run ADB tap**            | `subprocess.run(["adb", "shell", "input", "tap", "500", "500"])`                                                     |
| **Input text**             | `subprocess.run(["adb", "shell", "input", "text", "hello%sworld"])`                                                 |
| **Post notification**      | `subprocess.run(["adb", "shell", "cmd", "notification", "post", "-S", "bigtext", "-t", "Title", "tag", "Hello!"])`  |
| **Full script example**    | See below                                                                                                             |

---

## Full Python Example with Error Handling
```python
import subprocess

try:
    cmd = ["adb", "shell", "input", "tap", "500", "500"]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    print("Output:", result.stdout)
except subprocess.CalledProcessError as e:
    print("Error:", e.stderr)
```

---

## pyautogui + ADB Integration
```python
import pyautogui
import subprocess

loc = pyautogui.locateOnScreen('button.png', confidence=0.8)
if loc:
    x, y = pyautogui.center(loc)
    subprocess.run(["adb", "shell", "input", "tap", str(x), str(y)])
else:
    print("Image not found.")
```
