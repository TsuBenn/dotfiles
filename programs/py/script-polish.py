import re
import subprocess
import sys
import ollama

MODEL = "gemma4:12b"
MAX_CHARS = 9999
SOUND_PATH = "/home/tsubenn/.config/quickshell/tui/assets/sfx/wow.mp3"  # put your own path here

SYSTEM_PROMPT = """You are an editor for YouTube video scripts.
Fix grammar and spelling, and lightly polish the wording so it flows well when spoken.
Keep the original meaning, tone, and structure. Do not add new ideas or remove points.
Keep any markdown headers exactly as they are.
Write like a person talking: use commas, periods, or parentheses instead of em dashes.
Return only the edited script, no commentary."""

def clean_dashes(text):
    return re.sub(r"\s*—\s*", ", ", text)

def split_sections(text):
    parts = re.split(r"(?m)^(?=#{1,6} )", text)
    return [p for p in parts if p.strip()]


def split_paragraphs(text, max_chars=MAX_CHARS):
    paragraphs = text.split("\n\n")
    chunks = []
    current = ""

    for p in paragraphs:
        if current and len(current) + len(p) + 2 > max_chars:
            chunks.append(current)
            current = p
        else:
            current = current + "\n\n" + p if current else p

    if current:
        chunks.append(current)
    return chunks


def split_chunks(text):
    chunks = []
    for section in split_sections(text):
        if len(section) <= MAX_CHARS:
            chunks.append(section.strip())
        else:
            chunks.extend(split_paragraphs(section))
    return chunks


def polish(text):
    response = ollama.chat(
        model=MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        think=False,
        options={"temperature": 0.3, "num_ctx": 16384, "use_mmap": False},
    )
    return clean_dashes(response["message"]["content"].strip())

def play_sound():
    try:
        subprocess.run(["paplay", SOUND_PATH], check=True)
    except FileNotFoundError:
        print("paplay not found, skipping sound.")
    except subprocess.CalledProcessError:
        print("paplay failed, check your sound path.")


def main():
    if len(sys.argv) != 2:
        print("Usage: python polish.py script.txt")
        sys.exit(1)

    in_path = sys.argv[1]
    with open(in_path, "r", encoding="utf-8") as f:
        text = f.read()

    chunks = split_chunks(text)
    out_path = in_path.replace(".txt", "_polished.txt")

    with open(out_path, "w", encoding="utf-8") as out:
        for i, chunk in enumerate(chunks, start=1):
            print(f"Polishing chunk {i}/{len(chunks)}...")
            result = polish(chunk)

            if i > 1:
                out.write("\n\n")
            out.write(result)
            out.flush()

    print(f"Saved to {out_path}")
    play_sound()


if __name__ == "__main__":
    main()
