#!/usr/bin/env python3

import sys
import json
import ollama
import tomllib
from pathlib import Path

MODEL = "gemma3:12b"


PROMPT = """
You are a strict validator.

Given a multiple choice question, determine the correct answer.

Rules:
- Do NOT explain.
- Do NOT add extra text.
- Return ONLY the correct answer.
- If multiple answers are correct, return a JSON list.
- The answer MUST match exactly one or more of the given choices.

Question:
{question}

Choices:
{choices}
"""


def ask_model(question, choices):
    prompt = PROMPT.format(
        question=question,
        choices="\n".join(f"- {c}" for c in choices)
    )

    response = ollama.chat(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
    )

    raw = response["message"]["content"].strip()

    # Try parsing list
    try:
        return json.loads(raw)
    except:
        return raw.strip('"')


def normalize_answer(ans):
    ans = str(ans)
    if isinstance(ans, list):
        return sorted(a.strip() for a in ans)
    return [ans.strip()]


def validate_question(q):
    model_ans = ask_model(q["question"], q["choices"])
    model_ans = normalize_answer(model_ans)

    correct_ans = normalize_answer(q["answer"])

    return model_ans == correct_ans, model_ans


def main():
    if len(sys.argv) < 2:
        print("Usage: python study_validate.py <file.toml>")
        sys.exit(1)

    path = Path(sys.argv[1])

    with open(path, "rb") as f:
        data = tomllib.load(f)

    questions = data.get("questions", [])

    correct = 0
    wrong = 0

    for i, q in enumerate(questions, 1):
        ok, model_ans = validate_question(q)

        if ok:
            print(f"[{i}] ✓ Correct")
            correct += 1
        else:
            print(f"[{i}] ✗ Wrong")
            print(f"  Q: {q['question']}")
            print(f"  Your answer: {q['answer']}")
            print(f"  Model answer: {model_ans}")
            wrong += 1

    print("\n──────────────")
    print(f"Correct: {correct}")
    print(f"Wrong: {wrong}")


if __name__ == "__main__":
    main()
