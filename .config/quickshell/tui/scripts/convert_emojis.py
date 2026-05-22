import json
import re

def parse_emoji_file(input_path, output_path):
    groups = {}

    with open(input_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            parts = line.split("\t")
            if len(parts) < 5:
                continue

            emoji     = parts[0].strip()
            group     = parts[1].strip()
            subgroup  = parts[2].strip()
            name      = parts[3].strip()
            tags_raw  = parts[4].strip()

            keywords = [subgroup, name] + [t.strip() for t in tags_raw.split("|")]
            description = f"{name.capitalize()} <i>{group}</i>"

            entry = {
                "label": emoji,
                "description": description,
                "keywords": keywords,
                "category": "emoji",
                "value": ["bash", "-c", f"sleep 0.2 && wtype {emoji}"],
                "type": "exec",
            }

            if group not in groups:
                groups[group] = []
            groups[group].append(entry)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(groups, f, ensure_ascii=False, indent=4)

    print(f"Done! Written to {output_path}")

parse_emoji_file("all_emojis.txt", "emojis.json")
