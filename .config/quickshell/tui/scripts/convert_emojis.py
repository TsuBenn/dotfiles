import json

def parse_emoji_file(input_path, output_path):
    emojis = []

    with open(input_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            parts = line.split("\t")
            if len(parts) < 5:
                continue

            emoji    = parts[0].strip()
            group    = parts[1].strip()
            subgroup = parts[2].strip()
            name     = parts[3].strip()
            tags_raw = parts[4].strip()

            keywords = [subgroup, name] + [t.strip() for t in tags_raw.split("|")]
            description = f"{name.capitalize()} <i>{group}</i>"

            emojis.append({
                "label": emoji,
                "description": description,
                "keywords": keywords,
                "group": group,
                "category": "emoji",
                "value": ["bash", "-c", f"sleep 0.2 && wtype {emoji}"],
                "type": "exec",
            })

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(emojis, f, ensure_ascii=False, indent=4)

    print(f"Done! {len(emojis)} emojis written to {output_path}")

parse_emoji_file("all_emojis.txt", "emojis.json")
