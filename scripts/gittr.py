import os
import subprocess

raw_dir = os.path.dirname(os.path.abspath(__file__))
_dir = os.path.dirname(raw_dir)

add = subprocess.run(["git", "add", "."], cwd=_dir)
commit = subprocess.run(["git", "commit", "-m", "fast"], cwd=_dir)
push = subprocess.run(["git", "push"], capture_output=True, text=True, cwd=_dir)
print(push.stdout.strip())
