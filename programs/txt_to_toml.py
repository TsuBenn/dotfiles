import re
import tomllib
import tomli_w

def parse_questions_from_text(content):
    """
    Parse questions from the text format into structured format.
    Expected format per question:
    
    **Number. Question text**
    A) Option A text
    B) Option B text
    C) Option C text
    D) Option D text
    
    **Answer: X**
    *Explanation: Full explanation text*
    """
    
    questions = []
    
    # Split by question markers
    lines = content.split('\n')
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Look for question pattern: **Number.**
        q_match = re.match(r'\*\*(\d+)\.\s*(.+?)\*\*', line)
        if q_match:
            q_num = q_match.group(1)
            q_text = q_match.group(2).strip()
            
            # Clean up any remaining markdown
            q_text = re.sub(r'\*\*', '', q_text)
            q_text = q_text.replace('\n', ' ').strip()
            
            # Move to next line to get choices
            i += 1
            choices = []
            
            # Get the next lines until we have 4 choices
            while len(choices) < 4 and i < len(lines):
                choice_line = lines[i].strip()
                choice_match = re.match(r'([A-D])[\).]\s*(.+)', choice_line)
                if choice_match:
                    choices.append(choice_match.group(2).strip())
                i += 1
            
            # Find answer line (may be further down)
            answer_letter = ""
            answer_text = ""
            explanation = ""
            
            # Look for answer in the next few lines
            j = i
            while j < min(len(lines), i + 15):
                answer_line = lines[j].strip()
                ans_match = re.search(r'\*\*Answer:\s*([A-D])\*\*', answer_line)
                if ans_match:
                    answer_letter = ans_match.group(1)
                    ans_idx = ord(answer_letter) - ord('A')
                    answer_text = choices[ans_idx] if ans_idx < len(choices) else answer_letter
                    # Check for explanation on same line
                    expl_match = re.search(r'\*Explanation:\*\*\s*(.+)', answer_line)
                    if expl_match:
                        explanation = expl_match.group(1).strip()
                    else:
                        # Check next lines for explanation
                        for k in range(1, 5):
                            if j + k < len(lines):
                                next_line = lines[j + k].strip()
                                expl_match2 = re.search(r'\*Explanation:\s+(.*?)\*', next_line)
                                if expl_match2:
                                    explanation = expl_match2.group(1).strip()
                                    break
                    break
                j += 1
            
            # If answer not found, try to find by pattern in remaining block
            if not answer_text and answer_letter:
                ans_idx = ord(answer_letter) - ord('A')
                answer_text = choices[ans_idx] if ans_idx < len(choices) else ""
            
            # Ensure we have exactly 4 choices
            while len(choices) < 4:
                choices.append("")
            
            # Build explanations list - only the correct answer gets an explanation
            explanations = ["", "", "", ""]
            if explanation and answer_letter:
                ans_idx = ord(answer_letter) - ord('A')
                if ans_idx < 4:
                    explanations[ans_idx] = explanation
            elif explanation and answer_text:
                # Try to find which choice matches the answer
                for idx, choice in enumerate(choices):
                    if choice == answer_text:
                        explanations[idx] = explanation
                        break
            
            question_obj = {
                "question": q_text,
                "choices": choices[:4],
                "answer": answer_text if answer_text else (choices[0] if choices else ""),
                "explanations": explanations
            }
            
            questions.append(question_obj)
        else:
            i += 1
    
    return questions


def questions_to_toml(questions, filename="questions_output.toml"):
    """
    Convert questions to TOML format and save to file.
    TOML format:
    
    [[questions]]
    question = "Question text"
    choices = ["Option A", "Option B", "Option C", "Option D"]
    answer = "Correct answer"
    explanations = ["Explanation for A", "", "", ""]
    """
    import tomli_w
    
    # Prepare data for TOML output
    output_data = {"questions": questions}
    
    # Write TOML file
    with open(filename, 'wb') as f:
        tomli_w.dump(output_data, f)
    
    print(f"Successfully wrote {len(questions)} questions to {filename}")


def questions_to_toml_pretty(questions, filename="questions_output.toml"):
    """
    Convert questions to TOML format with pretty formatting.
    Alternative method that manually formats for better readability.
    """
    with open(filename, 'w', encoding='utf-8') as f:
        f.write("# Computer Organization and Architecture - Practice Questions\n")
        f.write("# Generated from textbook questions\n\n")
        
        for idx, q in enumerate(questions):
            f.write(f"[[questions]]\n")
            f.write(f'question = "{escape_toml_string(q["question"])}"\n')
            f.write('choices = [\n')
            for choice in q["choices"]:
                f.write(f'    "{escape_toml_string(choice)}",\n')
            f.write(']\n')
            f.write(f'answer = "{escape_toml_string(q["answer"])}"\n')
            f.write('explanations = [\n')
            for expl in q["explanations"]:
                f.write(f'    "{escape_toml_string(expl)}",\n')
            f.write(']\n\n')
    
    print(f"Successfully wrote {len(questions)} questions to {filename}")


def escape_toml_string(s):
    """Escape special characters in string for TOML output."""
    if s is None:
        return ""
    # Escape backslashes and quotes
    s = s.replace('\\', '\\\\')
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    s = s.replace('\r', '\\r')
    return s


def parse_questions_from_mcq_bank(content):
    """
    Specialized parser for the MCQ bank format in the provided content.
    This format has questions with:
    
    **Number. Question text?**
    A) Option A
    B) Option B
    C) Option C
    D) Option D
    
    **Answer: X**
    *Explanation: Explanation text*
    """
    questions = []
    
    # Split by double newlines to get question blocks
    blocks = re.split(r'\n\s*\n', content)
    
    for block in blocks:
        if not block.strip():
            continue
        
        # Extract question number and text
        q_match = re.search(r'\*\*(\d+)\.\s*(.+?)\*\*', block, re.DOTALL)
        if not q_match:
            continue
        
        q_num = q_match.group(1)
        q_text = q_match.group(2).strip()
        # Clean up markdown
        q_text = re.sub(r'\*\*', '', q_text)
        q_text = ' '.join(q_text.split())
        
        # Extract choices (A, B, C, D)
        choices = []
        choice_pattern = r'\n([A-D])[\)\.]\s*(.+?)(?=\n[A-D][\)\.]|\n\*\*Answer:|\Z)'
        choice_matches = re.findall(choice_pattern, block, re.DOTALL)
        
        for letter, text in choice_matches:
            choices.append(' '.join(text.strip().split()))
        
        # If we didn't get 4 choices, try alternative pattern
        if len(choices) != 4:
            choices = []
            for letter in ['A', 'B', 'C', 'D']:
                pattern = rf'\n{letter}[\)\.]\s*(.+?)(?=\n[B-D][\)\.]|\n\*\*Answer:|\Z)'
                match = re.search(pattern, block, re.DOTALL)
                if match:
                    choices.append(' '.join(match.group(1).strip().split()))
        
        # Extract answer letter
        answer_match = re.search(r'\*\*Answer:\s*([A-D])\*\*', block)
        if not answer_match:
            continue
        
        answer_letter = answer_match.group(1)
        ans_idx = ord(answer_letter) - ord('A')
        answer_text = choices[ans_idx] if ans_idx < len(choices) else answer_letter
        
        # Extract explanation
        explanation_match = re.search(r'\*Explanation:\*\*\s*(.+?)(?=\n\*\*|\n\n|$)', block, re.DOTALL)
        if not explanation_match:
            explanation_match = re.search(r'Explanation:\s*(.+?)(?=\n\*\*|\n\n|$)', block, re.DOTALL)
        
        explanation = ""
        if explanation_match:
            explanation = ' '.join(explanation_match.group(1).strip().split())
        
        # Ensure exactly 4 choices
        while len(choices) < 4:
            choices.append("")
        
        # Build explanations list
        explanations = ["", "", "", ""]
        if explanation and ans_idx < 4:
            explanations[ans_idx] = explanation
        
        question_obj = {
            "question": q_text,
            "choices": choices[:4],
            "answer": answer_text,
            "explanations": explanations
        }
        
        questions.append(question_obj)
    
    return questions


def main():
    # Read the input file containing all questions
    input_filename = "cea_ai.txt"  # Change this to your file name
    output_toml = "cea_ai_stable.toml"
    
    try:
        with open(input_filename, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File '{input_filename}' not found.")
        print("Please ensure your questions file is named 'questions.txt' or modify the filename in the script.")
        return
    
    # Try specialized parser first (for the format in this conversation)
    questions = parse_questions_from_mcq_bank(content)
    
    # If no questions found, try the general parser
    if not questions:
        print("Specialized parser found no questions. Trying general parser...")
        questions = parse_questions_from_text(content)
    
    if not questions:
        print("Error: Could not parse any questions from the file.")
        print("Please check the format. Expected format:")
        print("\n**1. Question text?**")
        print("A) Option A")
        print("B) Option B")
        print("C) Option C")
        print("D) Option D")
        print("\n**Answer: A**")
        print("*Explanation: Explanation text*")
        return
    
    # Output in TOML format
    questions_to_toml(questions, output_toml)
    

if __name__ == "__main__":
    main()
