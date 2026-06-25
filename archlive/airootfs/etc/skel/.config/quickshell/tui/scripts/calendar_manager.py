import json
import re
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REMINDERS_DIR = os.path.join(SCRIPT_DIR, "reminders.json")
EVENTS_DIR = os.path.join(SCRIPT_DIR, "events.json")

def load_reminders():
    try:
        with open(REMINDERS_DIR, "r") as file:
            return json.load(file)
    except:
        return {}

def load_events():
    try:
        with open(EVENTS_DIR, "r") as file:
            return json.load(file)
    except:
        return {}

def save_reminders(data):
    with open(REMINDERS_DIR, "w") as file:
        json.dump(data, file, indent=2)

def save_events(data):
    with open(EVENTS_DIR, "w") as file:
        json.dump(data, file, indent=2)

def parse_input(input):
    tags = re.findall(r"(?<!\S)-([a-zA-Z]+)\b",input)
    tags = [char for tag in tags for char in tag]
    paths = re.findall(r"--([\S]+=[\S]+)",input)
    query = " ".join(re.sub(r"(?<!\S)-[a-zA-Z]+\b","",input).strip().split())
    query = " ".join(re.sub(r"--([\S]+)","",query).strip().split())
    return tags, query, paths

def main():

    tags, query, paths = parse_input(" ".join(sys.argv[1:]))
    print(parse_input(" ".join(sys.argv[1:])))

    date = ""
    title = query
    body = ""
    urgency = 0
    time = ""
    index = -1
    span = 1

    if "m" in tags:
        data = load_events()
    else:
        data = load_reminders()

    for path in paths:
        if "=" in path:
            var = path.split("=")
            if var[0] == "date":
                date = var[1]
            if var[0] == "urgency":
                urgency = int(var[1])
            if var[0] == "time":
                time = var[1]
            if var[0] == "index":
                index = int(var[1])
            if var[0] == "body":
                body = " ".join(var[1].split("-"))
            if var[0] == "span":
                span = int(var[1]) if int(var[1]) > 0 else 1

    if "a" in tags:
        if not query:
            print("Title required for adding new reminder.")
            return
        if not date in data:
            print(f"No reminders found on {date}")
            data[date] = [{
                "title": title,
                "body": body,
                "span": span,
                "urgency": urgency,
                "time": time,
            }]
        else:
            print(f"Reminders found on {date}")
            data[date].append({
                "title": title,
                "body": body,
                "span": span,
                "urgency": urgency,
                "time": time,
            })

    if "e" in tags:
        if index == -1:
            print(f"Index not specified for editing")
        elif not date in data:
            print(f"No reminders found on {date}")
        else:
            print(f"Reminders found on {date}")
            data[date][index] = {
                "title": title,
                "body": body,
                "span": span,
                "urgency": urgency,
                "time": time,
            }

    if "r" in tags:
        if index == -1:
            print(f"Index not specified, removing the whole date...")
            data.pop(date, None)
            if "s" in tags:
                save_events(data)
        elif not date in data:
            print(f"No reminders found on {date}")
        else:
            print(f"Reminders found on {date}")
            data[date].pop(index)

    if "s" in tags:
        print(f"Saving...")

        empty_date = []

        for date in data:
            if len(data[date]) == 0:
                empty_date.append(date)

        for date in empty_date:
            data.pop(date)

        if "m" in tags:
            save_events(data)
        else:
            save_reminders(data)

        print(f"Saved!")

    if "p" in tags:
        print(json.dumps(data,indent=2))

    if "P" in tags:
        print(f"date: {date}, title: {title}, body: {body}, urgency: {urgency}, time: {time}")
                


main()
