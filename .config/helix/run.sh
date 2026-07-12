#!/usr/bin/env bash

FILE_PATH="$1"
EXT="${FILE_PATH##*.}"
BASE_NAME=$(basename "$FILE_PATH")
cols=$(tput cols 2>/dev/null || echo 80)

# 1. Prompt for environment variables first
read -p "Env vars (e.g. KEY=val): " ENV_VARS

# 2. Prompt for arguments
read -p "Args for $BASE_NAME: " ARGS

# Loop from 1 up to the total number of columns to print the separator line
for ((i=0; i<cols; i++))
do
    printf "─"
done
echo "" # Ensure the program output starts on a fresh line below the border

case "$EXT" in
    py)
        eval $ENV_VARS python3 "$FILE_PATH" $ARGS
        ;;
    c)
        gcc "$FILE_PATH" -o /tmp/hx_c_out && eval $ENV_VARS /tmp/hx_c_out $ARGS
        ;;
    cpp|cc|cxx)
        g++ "$FILE_PATH" -o /tmp/hx_cpp_out && eval $ENV_VARS /tmp/hx_cpp_out $ARGS
        ;;
    rs)
        if cargo verify-project &>/dev/null; then
            eval $ENV_VARS cargo run -- $ARGS
        else
            rustc "$FILE_PATH" -o /tmp/hx_rs_out && eval $ENV_VARS /tmp/hx_rs_out $ARGS
        fi
        ;;
    lua)
        eval $ENV_VARS lua "$FILE_PATH" $ARGS
        ;;
    js|ts)
        node "$FILE_PATH" $ARGS
        ;;
    *)
        echo "Error: Extension '.$EXT' is not configured in hx-run."
        ;;
esac

echo ""
read -n1 -s -r -p "Press any key to close..."
