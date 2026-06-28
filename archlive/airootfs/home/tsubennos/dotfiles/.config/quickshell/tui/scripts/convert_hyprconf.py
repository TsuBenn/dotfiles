import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(SCRIPT_DIR, "hyprland.lua")) as f:
    data = f.read() 
    data = "SET_COLOR=\"" + data.replace("\"","\\\"") + "\""
    print(data)
