
#!/usr/bin/env python3
"""
png_to_toml.py
Converts a folder of PNG images (exam/quiz pages) into a study TOML file
using a local Ollama vision model.

Usage:
    python png_to_toml.py <folder> [output.toml]

Requirements:
    pip install ollama --break-system-packages
"""

import sys
import os
import time
import base64
import json
import json5
import re
import tomllib
from pathlib import Path

try:
    import ollama
except ImportError:
    print("Missing dependency. Run: pip install ollama --break-system-packages")
    sys.exit(1)

# ─── Config ───────────────────────────────────────────────────────────────────

MODEL = "qwen3.5:9b"

PROMPT = """Extract the text of the following image.
Your output must follow this format:
```
Question: text of question

Choices:
A. text of option A
B. text of option B 
C. text of option C 
D. text of option D

Answers: A
```

Always include "Question:", "Choices:", and "Answers:"
Do not reason on the choices or the answers."""

# ─── Helpers ──────────────────────────────────────────────────────────────────

def encode_image(path: Path) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")

def natural_sort_key(path: Path):
    """Sort filenames naturally so page2 comes before page10."""
    parts = re.split(r'(\d+)', path.stem)
    return [int(p) if p.isdigit() else p.lower() for p in parts]

def parse_question(raw_text, filename):
    text = raw_text.strip()

    # Normalize line endings + spacing
    text = re.sub(r'\r\n?', '\n', text)

    # --- Extract QUESTION ---
    q_match = re.search(
        r'question\s*:\s*(.*?)(?=\n\s*choices\s*:|\n\s*answers\s*:|$)',
        text,
        re.IGNORECASE | re.DOTALL
    )
    question = q_match.group(1).strip() if q_match else ""

    # --- Extract CHOICES BLOCK ---
    c_match = re.search(
        r'choices\s*:\s*(.*?)(?=\n\s*answers\s*:|$)',
        text,
        re.IGNORECASE | re.DOTALL
    )
    choices_block = c_match.group(1).strip() if c_match else ""

    # --- Extract ANSWER ---
    a_match = re.search(
        r'answers\s*:\s*([A-Z])',
        text,
        re.IGNORECASE
    )
    answer = a_match.group(1).upper() if a_match else ""

    # --- Extract INDIVIDUAL CHOICES (robust regex) ---
    choices = re.findall(
        r'([A-Z])\.\s*(.*?)(?=\s+[A-Z]\.|$)',
        choices_block,
        re.DOTALL
    )

    # Format choices nicely
    formatted_choices = [
        f"{letter}. {content.strip()}"
        for letter, content in choices
    ]

    if not question or not formatted_choices or not answer:
        return []

    return [{
        "filename": filename,
        "question": question,
        "choices": formatted_choices,
        "answer": answer
    }]

def extract_questions(image_path: Path) -> list[dict]:

    image_b64 = encode_image(image_path)

    try:
        response = ollama.chat(
            model=MODEL,
            think= False,
            messages=[
                {
                    "role": "user",
                    "content": PROMPT,
                    "images": [image_b64],
                }
            ],
            options={
                'num_predict': 2048, # Ensures it has enough tokens for long questions
                'num_ctx': 8192,
                'temperature': 0.2,
                # 'repeat_penalty': 1.2,
            }
        )
    except Exception as e:
        print(f"  ✗ Ollama error: {e}")
        return []

    raw = response["message"]["content"].strip()


    result = parse_question(raw, Path(image_path).name)


    try:
        if isinstance(result, list) and result:
            return result
        print(f"  ✗ Unexpected JSON shape, skipping")
        print(raw)
        print(json.dumps(result,indent=4))
        return []
    except json.JSONDecodeError as e:
        print(f"  ✗ Failed to parse JSON: {e}")
        print(f"  Raw response: {raw}")
        print(raw)
        print(json.dumps(result,indent=4))
        return []


def validate_question(q: dict) -> bool:
    """Basic sanity check on extracted question."""
    if not isinstance(q.get("question"), str):
        return False
    if not isinstance(q.get("choices"), list) or len(q["choices"]) < 2:
        return False
    answer = q.get("answer")
    if isinstance(answer, list):
        return all(a in q["choices"] for a in answer)
    return answer in q["choices"]


def transform_json_to_string(data):
    if "answer" not in data or "choices" not in data or "question" not in data:
        raise ValueError(f"Missing required keys in: {data}")

    clean_choices = []
    for choice in data["choices"]:
        cleaned = re.sub(r'^[A-Z]\.\s*', '', choice).strip()
        clean_choices.append(cleaned)

    letter_to_index = {chr(65 + i): i for i in range(len(clean_choices))}

    # Normalize answer to always be a list of letters
    raw_answer = data["answer"]
    if isinstance(raw_answer, str):
        letters = [c for c in raw_answer if c.isupper()]
        raw_answer = letters if letters else [raw_answer]

    if isinstance(raw_answer, str):
        if len(raw_answer) > 1 and all(c.isupper() for c in raw_answer.replace(" ", "").replace(",", "")):
            raw_answer = [c for c in raw_answer if c.isupper()]
        else:
            raw_answer = [raw_answer]

    answer_texts = [clean_choices[letter_to_index[a]] for a in raw_answer]

    # Single answer stays as string, multiple as list
    if len(answer_texts) == 1:
        answer_toml = json.dumps(answer_texts[0])
    else:
        answer_toml = "[" + ", ".join(json.dumps(a) for a in answer_texts) + "]"

    return (
        f"[[questions]]\n"
        f"filename = {json.dumps(data['filename'])}\n"
        f"question = {json.dumps(data['question'])}\n"
        f"choices = [{', '.join(json.dumps(c) for c in clean_choices)}]\n"
        f"answer = {answer_toml}"
    )

def to_toml_str(questions: list[dict]) -> str:
    output = []
    for q in questions:
        output.append(transform_json_to_string(q))
        output.append("")
    return "\n".join(output)

from concurrent.futures import ThreadPoolExecutor, as_completed

MAX_WORKERS = 1  # start small
MAX_RETRIES = 3  # start small
PROGRESS_FILE = Path(__file__).resolve().parent / "processed.txt"

def load_processed():
    if not os.path.exists(PROGRESS_FILE):
        return set()
    with open(PROGRESS_FILE, "r") as f:
        return set(line.strip() for line in f)

def mark_processed(filename):
    with open(PROGRESS_FILE, "a") as f:
        f.write(filename + "\n")

def process_image(png):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            questions = extract_questions(png)
            valid = [q for q in questions]
            skipped = len(questions) - len(valid)

            # ✅ success condition
            if valid:
                return png.name, valid, skipped, attempt

            # ❌ no valid questions → retry
            print(f"(retry {attempt}) no valid questions")

        except Exception as e:
            print(f"(retry {attempt}) error: {e}")

        # small delay before retry (important)
        time.sleep(0.5)

    # ❌ failed after all retries
    return png.name, [], 0, MAX_RETRIES

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: python png_to_toml.py <folder> [output.toml]")
        sys.exit(1)

    folder = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) >= 3 else folder / "questions.toml"
    temp_output = Path(sys.argv[2].replace(".toml","_temp.toml")) if len(sys.argv) >= 3 else folder / "questions_temp.toml"

    if not folder.is_dir():
        print(f"Error: '{folder}' is not a directory.")
        sys.exit(1)

    pngs = sorted(
        [p for p in folder.iterdir() if p.suffix.lower() == ".png"],
        key=natural_sort_key
    )

    processed = load_processed()

    pngs = [p for p in pngs if p.name not in processed]

    if not pngs:
        print("No PNG files found.")
        sys.exit(1)

    print(f"Found {len(pngs)} PNG(s) in '{folder}'")
    print(f"Model: {MODEL}")
    print(f"Output: {output}\n")

    all_questions = []
    failed_pages = []

    """
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(process_image, png): png for png in pngs}

        for i, future in enumerate(as_completed(futures), 1):
            png = futures[future]
            print(f"[{i}/{len(pngs)}] Processing {png.name} ...", end=" ")

            try:
                name, valid, skipped, attempts = future.result()

                if valid:
                    all_questions.extend(valid)
                    mark_processed(name)
                    print(f"({attempts} tries)" if not skipped else "(skipped)")
                    toml_content = to_toml_str(all_questions)
                    temp_output.write_text(toml_content, encoding="utf-8")
                else:
                    print("— no questions found")
                    failed_pages.append(name)

            except Exception as e:
                print(f"✗ error: {e}")
                failed_pages.append(png.name)
                break
    """

    for i, png in enumerate(pngs, 1):
        print(f"[{i}/{len(pngs)}] Processing {png.name} ...", end=" ", flush=True)
        name, valid, skipped, attempt = process_image(png)


        if valid:
            all_questions.extend(valid)
            mark_processed(name)
            print(f"✓ {len(valid)} question(s) extracted" + (f" ({skipped} skipped)" if skipped else ""))
            toml_content = to_toml_str(all_questions)
            temp_output.write_text(toml_content, encoding="utf-8")
        else:
            print("— no questions found")
            failed_pages.append(png.name)



    print(f"\n─────────────────────────────")
    print(f"Total questions extracted: {len(all_questions)}")

    if failed_pages:
        print(f"Pages with no questions ({len(failed_pages)}): {'\n'.join(failed_pages)}")
    else:
        os.remove("processed.txt")

    if not all_questions:
        print("Nothing to save.")
        sys.exit(0)

    toml_content = to_toml_str(all_questions)
    output.write_text(toml_content, encoding="utf-8")
    print(f"\nSaved to: {output}")


if __name__ == "__main__":
    start = time.time()
    main() 

    end = time.time()
    print(f"\nTotal time: {end - start:.2f} seconds")
