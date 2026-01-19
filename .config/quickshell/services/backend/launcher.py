import os
import sys
import configparser
import json
import math
import urllib.parse

DESKTOP_DIRS = {
    "/usr/share/applications/",
    "/usr/local/share/applications/",
    os.environ['HOME'] + "/.local/share/applications/"
}

def load_apps():
    apps = []

    for dir in DESKTOP_DIRS:
        if not os.path.isdir(dir):
            continue

        for file in os.listdir(dir):
            if not file.endswith(".desktop"):
                continue

            path = os.path.join(dir, file)

            parser = configparser.ConfigParser(interpolation=None)

            try:
                parser.read(path)
                entry = parser['Desktop Entry']
            except Exception:
                continue
            
            if entry.get("NoDisplay") == "true":
                continue

            name = entry.get("Name")
            generic_name = entry.get("GenericName")
            keywords = entry.get("Keywords")
            exec = entry.get("Exec")
            icon = entry.get("Icon")

            if not name or not exec:
                continue

            apps.append(
                {
                    "name": name,
                    "generic_name": generic_name,
                    "exec": exec,
                    "keywords": keywords,
                    "icon": icon,
                }
            )


    return apps


def main():

    query = sys.argv[1].lower() if len(sys.argv) > 1 else ""

    if query:
        if query[0] == ">":
            print("settings search")


        elif query[0] == "/":
            print("fzf")

            
        elif query[0] == "?":
            search = [{
                "name": "Google: " + query[1:],
                "exec": f"xdg-open \"https://www.google.com/search?q=" + urllib.parse.quote(query[1:],safe='/',encoding=None,errors=None) + "\"", 
                "icon": "kitty", 
            }]

            print(json.dumps(search))


        elif query[0] == "=":
            def safe_eval(expressions):
                try:
                    return str(eval(expressions.strip()))
                except:
                    return "Invalid Expressions!"

            calculate = safe_eval(query[1:]) 

            result = [{
                "name": calculate,
                "exec": f"echo '{calculate}' | wl-copy", 
                "icon": "kitty", 
            }]

            print(json.dumps(result))


        else:
            apps = [
                app for app in load_apps() if (query in app["name"].lower()) or (query in (app["generic_name"] or "").lower()) or (query in (app["keywords"] or "").lower())
            ]

            print(json.dumps(apps)) 



    else:
        print("No Query Entered!")
    

if __name__ == "__main__":
    main()

