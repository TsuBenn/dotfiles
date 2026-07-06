#!/usr/bin/env python3
import os
import sys
import json

def main():
    # 1. Check if a directory argument was provided
    if len(sys.argv) < 2:
        print("Usage: python script.py <directory_path>")
        sys.exit(1)

    target_dir = sys.argv[1]

    # 2. Check if the provided path is actually a directory
    if not os.path.isdir(target_dir):
        print(f"Error: '{target_dir}' is not a valid directory.")
        sys.exit(1)

    result_dict = {}

    # 3. Loop through all files in the target directory
    for filename in os.listdir(target_dir):
        # Filter for files ending with .txt
        if filename.endswith('.txt'):
            file_path = os.path.join(target_dir, filename)

            # Check if it's a file (and not a directory named 'something.txt')
            if os.path.isfile(file_path):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        # Split the extension and grab just the name part
                        file_name_without_ext = os.path.splitext(filename)[0]

                        # Store it in the dictionary
                        result_dict[file_name_without_ext] = f.read()
                except Exception as e:
                    print(f"Warning: Could not read {filename}. Error: {e}", file=sys.stderr)

    # 4. Convert the dictionary to a valid JSON string and print it
    json_output = json.dumps(result_dict, indent=2)
    print(json_output)

if __name__ == "__main__":
    main()
