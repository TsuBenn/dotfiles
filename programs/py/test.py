import subprocess
import signal

def shutdown():
    subprocess.run(["notify-send", "DB Worker", f"Shutting down"])


