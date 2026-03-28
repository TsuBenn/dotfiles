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

MODEL = "gemma3:12b"

PROMPT = """You are a data extraction assistant. Your task is to analyze the provided image containing a multiple-choice question and extract the question, choices, and correct answer into a strict JSON format.

### STEP 1: TOP SECTION (White Background)
- Ignore any diagrams or images.
- Transcribe the English question.
- Pay extra attention to characters like '.
- Transcribe the choices (A, B, C, D) into a dictionary. 

### STEP 2: BOTTOM SECTION (Colored Background Bar)
- Find the large, bold letter(s) at the very start of the bottom bar (e.g., "A" or "BC").
- These letters are the ONLY source for the 'answer' field.

Here is a generic example showing the EXACT structure you must use:
[
  {
    "question": "What is the capital of France?",
    "choices": [
      "A. Berlin",
      "B. London",
      "C. Paris",
      "D. Madrid"
    ],
    "answer": "A"
  }
]

Here is a example of multiple answers:
[
  {
    "question": "What is a component of a computer?",
    "choices": [
      "A. CPU",
      "B. RAM",
      "C. KEYBOARD",
      "D. MOUSE"
    ],
    "answer": ["A","B"]
  }
]

Please follow these rules carefully:
1. Format: Output a JSON array containing an object with the keys "question", "choices", and "answer".
2. Question: Extract the question UNTIL it hits the first choice.
3. Choices: Extract all available options (Must have letters prefixes) into a list of strings. 
4. Answer: Identify the correct answer from the image. Only output the letter of the answer (A, B ,C ,etc.)
    * If there is only one correct answer, format it as a string: "answer": "Correct option"
    * If there are multiple correct answers (e.g. "ADE", "A, B, C, D", etc.), format them as a list of answers: "answer": ["correct option 1", "correct option 2"]
5. Explanations: Completely ignore any explanatory text, translations, or extra commentary below the answer(s).
6. Output: Return ONLY valid JSON. Do not include any conversational text, introductions, or markdown formatting blocks (like ```json). Remember to always escape characters like " with \\".
7. DO NOT SOLVE THE PROBLEM: Do not perform any calculations, math, or logical reasoning.
8. Do NOT output in any other languages apart from English for question, choices and answer(s).

Analyze the provided image and generate the JSON output now."""

# ─── Helpers ──────────────────────────────────────────────────────────────────

def encode_image(path: Path) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def natural_sort_key(path: Path):
    """Sort filenames naturally so page2 comes before page10."""
    parts = re.split(r'(\d+)', path.stem)
    return [int(p) if p.isdigit() else p.lower() for p in parts]


def try_fix_json(raw: str) -> str:
    # Replace smart/curly quotes with straight ones
    raw = raw.replace('\u2018', "'").replace('\u2019', "'")
    raw = raw.replace('\u201c', '"').replace('\u201d', '"')
    return raw

def extract_questions(image_path: Path) -> list[dict]:
    """Send image to Ollama and parse returned JSON."""
    image_b64 = encode_image(image_path)

    try:
        response = ollama.chat(
            model=MODEL,
            messages=[
                {
                    "role": "system",
                    "content": PROMPT,
                },
                {
                    "role": "user",
                    "content": "Extract the content from this image",
                    "images": [image_b64],
                }
            ],
            options={
                'num_predict': 8192, # Ensures it has enough tokens for long questions
                'num_ctx': 8192,
                'temperature': 0.1,
                'repeat_penalty': 1.2,
            }
        )
    except Exception as e:
        print(f"  ✗ Ollama error: {e}")
        return []

    raw = response["message"]["content"].strip()

    # Strip markdown fences if model ignores instructions
    raw = re.sub(r"^```(?:json)?\s*", "", raw)
    raw = re.sub(r"\s*```$", "", raw)
    raw = re.sub(r'\\_', '_', raw)
    print(f"  Raw response: {raw}")

    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return data
        print(f"  ✗ Unexpected JSON shape, skipping")
        return []
    except json.JSONDecodeError as e:
        print(f"  ✗ Failed to parse JSON: {e}")
        print(f"  Raw response: {raw}")
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

MAX_WORKERS = 2  # start small
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
