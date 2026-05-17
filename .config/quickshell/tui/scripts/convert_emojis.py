import json
import re


def transform_emoji_line(line):
    # Strip whitespace from ends
    line = line.strip()
    if not line:
        return None

    # Split by 2 or more spaces, or tabs, to separate the main columns
    parts = re.split(r"\s{2,}|\t", line)

    # Ensure we have the expected columns (at least emoji, group, subgroup, name)
    if len(parts) < 4:
        return None

    emoji = parts[0].strip()
    category_group = parts[1].strip()
    subgroup = parts[2].strip()
    name = parts[3].strip()

    # Capitalize the first letter of the name for the description
    capitalized_name = name.capitalize()
    description = f"{capitalized_name} <i>{category_group}</i>"

    # Gather keywords: include subgroup, name, and split the pipe-delimited tags
    keywords = [subgroup, name]

    if len(parts) > 4:
        # Split the remaining part by '|' and clean up spaces
        tags = [tag.strip() for tag in parts[4].split("|") if tag.strip()]
        keywords.extend(tags)

    # Remove duplicates from keywords while preserving order
    unique_keywords = list(dict.fromkeys(keywords))

    # Construct the final dictionary structure
    return {
        "label": emoji,
        "description": description,
        "keywords": unique_keywords,
        "category": "emoji",
        "value": ["bash", "-c", f"sleep 0.2 && wtype {emoji}"],
        "type": "exec",
    }


def convert_emoji_file(input_filename, output_filename):
    converted_emojis = []

    with open(input_filename, "r", encoding="utf-8") as infile:
        for line in infile:
            entry = transform_emoji_line(line)
            if entry:
                converted_emojis.append(entry)

    # Write out as a pretty-printed JSON array
    with open(output_filename, "w", encoding="utf-8") as outfile:
        json.dump(converted_emojis, outfile, ensure_ascii=False)


if __name__ == "__main__":
    # Change these filenames to match your local setup
    input_file = "all_emojis.txt"
    output_file = "emojis.json"

    convert_emoji_file(input_file, output_file)
    print(f"Successfully converted emojis to {output_file}!")
