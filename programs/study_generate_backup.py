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
import base64
import json
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

PROMPT = """You are an expert data extraction assistant. Your task is to analyze the provided image containing a multiple-choice question and extract the question, choices, and correct answer into a strict JSON format.

Please follow these rules carefully:
1. Format: Output a JSON array containing an object with the keys "question", "choices", and "answer".
2. Choices: Extract all available options into a list of strings. CRITICAL: Strip away the leading letters, numbers, and punctuation (e.g., "A. ", "B. ", "1) "). Extract ONLY the text content of the choice.
3. Answer: Identify the correct answer from the image. Do NOT output the letter (e.g., "B"). Instead, output the exact, full text of the correct choice from your "choices" list.
    * If there is only one correct answer, format it as a string: "answer": "Correct option text"
    * If there are multiple correct answers, format them as a list of strings: "answer": ["correct option 1", "correct option 2"]
4. Explanations: Completely ignore any explanatory text, translations, or extra commentary at the bottom of the image. Only use that lower section to figure out which option is correct so you can grab the matching text.
5. Output: Return ONLY valid JSON. Do not include any conversational text, introductions, or markdown formatting blocks (like ```json).
6. DO NOT SOLVE THE PROBLEM: Do not perform any calculations, math, or logical reasoning.

Example logic: 
- Image shows a math problem. 
- Image has a big "A" at the bottom.
- Choice A is "45". 
- Result: "answer": "45"

Here is a generic example showing the EXACT structure you must use:
[
  {
    "question": "What is the capital of France?",
    "choices": [
      "Berlin",
      "London",
      "Paris",
      "Madrid"
    ],
    "answer": "Paris"
  }
]

Analyze the provided image and generate the JSON output now."""

# ─── Helpers ──────────────────────────────────────────────────────────────────

def encode_image(path: Path) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def natural_sort_key(path: Path):
    """Sort filenames naturally so page2 comes before page10."""
    parts = re.split(r'(\d+)', path.stem)
    return [int(p) if p.isdigit() else p.lower() for p in parts]


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
                    "images": [image_path],
                }
            ],
            options={
                'temperature': 0,  # Forces the model to be more deterministic/literal
                'num_predict': 2048 # Ensures it has enough tokens for long questions
            }
        )
    except Exception as e:
        print(f"  ✗ Ollama error: {e}")
        return []

    raw = response["message"]["content"].strip()

    # Strip markdown fences if model ignores instructions
    raw = re.sub(r"^```(?:json)?\s*", "", raw)
    raw = re.sub(r"\s*```$", "", raw)

    try:
        data = json.loads(raw)
        if isinstance(data, list):
            return data
        print(f"  ✗ Unexpected JSON shape, skipping")
        return []
    except json.JSONDecodeError as e:
        print(f"  ✗ Failed to parse JSON: {e}")
        print(f"  Raw response: {raw[:200]}")
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


def to_toml_str(questions: list[dict]) -> str:
    """Manually build TOML string (no external lib needed)."""
    lines = []
    for q in questions:
        lines.append("[[questions]]")
        lines.append(f'question = {json.dumps(q["question"])}')

        choices_str = ", ".join(json.dumps(c) for c in q["choices"])
        lines.append(f"choices = [{choices_str}]")

        if isinstance(q["answer"], list):
            answer_str = ", ".join(json.dumps(a) for a in q["answer"])
            lines.append(f"answer = [{answer_str}]")
        else:
            lines.append(f"answer = {json.dumps(q['answer'])}")

        lines.append("")  # blank line between entries

    return "\n".join(lines)

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        print("Usage: python png_to_toml.py <folder> [output.toml]")
        sys.exit(1)

    folder = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) >= 3 else folder / "questions.toml"

    if not folder.is_dir():
        print(f"Error: '{folder}' is not a directory.")
        sys.exit(1)

    pngs = sorted(
        [p for p in folder.iterdir() if p.suffix.lower() == ".png"],
        key=natural_sort_key
    )

    if not pngs:
        print("No PNG files found.")
        sys.exit(1)

    print(f"Found {len(pngs)} PNG(s) in '{folder}'")
    print(f"Model: {MODEL}")
    print(f"Output: {output}\n")

    all_questions = []
    failed_pages = []

    for i, png in enumerate(pngs, 1):
        print(f"[{i}/{len(pngs)}] Processing {png.name} ...", end=" ", flush=True)
        questions = extract_questions(png)

        valid = [q for q in questions if validate_question(q)]
        skipped = len(questions) - len(valid)

        if valid:
            all_questions.extend(valid)
            print(f"✓ {len(valid)} question(s) extracted" + (f" ({skipped} skipped)" if skipped else ""))
        else:
            print("— no questions found")
            failed_pages.append(png.name)

    print(f"\n─────────────────────────────")
    print(f"Total questions extracted: {len(all_questions)}")

    if failed_pages:
        print(f"Pages with no questions ({len(failed_pages)}): {', '.join(failed_pages)}")

    if not all_questions:
        print("Nothing to save.")
        sys.exit(0)

    toml_content = to_toml_str(all_questions)
    output.write_text(toml_content, encoding="utf-8")
    print(f"\nSaved to: {output}")


if __name__ == "__main__":
    main()
