import os, time
import subprocess

raw_dir = os.path.dirname(os.path.abspath(__file__))
_dir = os.path.dirname(raw_dir)

add = subprocess.run(["git", "add", "."], capture_output=True, text=True, cwd=_dir)
print(add.stdout.strip())
time.sleep(5)
commit = subprocess.run(["git", "commit", "-m", "fast"], capture_output=True, text=True, cwd=_dir)
print(commit.stdout.strip())
time.sleep(5)
push = subprocess.run(["git", "push"], capture_output=True, text=True, cwd=_dir)
print(push.stdout.strip())
time.sleep(15)
