#!/bin/bash

# Ensure a directory argument was passed
if [[ -z "$1" ]]; then
    echo "Error: Please provide a target directory path."
    echo "Usage: $0 /path/to/media [max_jobs] [--force]"
    exit 1
fi

# SANITIZE PATH: Convert relative paths and clear trailing slashes
TARGET_DIR=$(readlink -f "${1%/}")

# Double-check that the resolved path actually exists and is a directory
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: '$TARGET_DIR' is not a valid directory."
    exit 1
fi

# --- DYNAMIC MAX_JOBS ENGINE ---
MAX_JOBS=12
if [[ -n "$2" ]]; then
    if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -gt 0 ]; then
        MAX_JOBS="$2"
    else
        echo "Warning: '$2' is not a valid number of jobs. Falling back to default (12)."
    fi
fi

# --- FORCE REGEN ENGINE ---
FORCE_REGEN=false
if [[ "$3" == "--force" ]]; then
    FORCE_REGEN=true
    echo "Force mode enabled: Regenerating all thumbnails..."
else
    echo "Incremental mode: Skipping existing thumbnails..."
fi

echo "Running with a maximum of $MAX_JOBS concurrent processes..."

# Create the hidden cache folder safely inside the targeted directory
mkdir -p "$TARGET_DIR/.qscache"

for file in "$TARGET_DIR"/*; do
    # Skip directories and the cache folder itself
    [[ -d "$file" ]] && continue

    # Extract just the filename from the path
    filename=$(basename "$file")

    # Predict the target thumbnail path
    thumb_path="$TARGET_DIR/.qscache/${filename}_thumb.jpg"

    # CACHE CHECK: If the thumbnail exists AND force is false, skip it
    if [[ -f "$thumb_path" ]] && [[ "$FORCE_REGEN" == "false" ]]; then
        continue
    fi

    # Extract the file extension and convert to lowercase
    ext="${filename##*.}"
    ext_lower=$(echo "$ext" | tr 'A-Z' 'a-z')

    # --- PROCESS IN THE BACKGROUND ---
    case "$ext_lower" in
        mp4)
            echo "Processing video: $filename"
            ffmpeg -y -ss 00:00:05 -i "$file" -vframes 1 -vf "scale=1920:-1" -q:v 8 "$thumb_path" 2>/dev/null &
            ;;
        jpg|jpeg|png|webp)
            echo "Processing image: $filename"
            magick "$file" -resize 1920x -quality 40 "$thumb_path" &
            ;;
        *)
            # Skip unsupported formats gracefully
            continue
            ;;
    esac

    # --- JOB LIMITER ENGINE ---
    while [ $(jobs -p | wc -l) -ge $MAX_JOBS ]; do
        sleep 0.05
    done
done

# Wait for the remaining background jobs to finish before exiting completely
wait
echo "Done! Check the '$TARGET_DIR/.qscache' directory."
