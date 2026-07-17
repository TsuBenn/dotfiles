use std::io::{self, BufRead, Write};
use std::path::Path;
use symspell::{AsciiStringStrategy, SymSpell, SymSpellBuilder, Verbosity};

const DICTIONARY_PATH: &str = "words.txt";

fn main() {
    // 1. Initialize SymSpell using the Builder pattern
    let mut symspell: SymSpell<AsciiStringStrategy> = SymSpellBuilder::default()
        .max_dictionary_edit_distance(2)
        .prefix_length(7)
        .count_threshold(1)
        .build()
        .unwrap();

    // 2. Load the wordlist at startup
    if Path::new(DICTIONARY_PATH).exists() {
        let _ = symspell.load_dictionary(DICTIONARY_PATH, 0, 1, " ");
    }

    let stdin = io::stdin();
    let mut stdout = io::stdout();

    // 3. Listen continuously to stdin lines
    for line in stdin.lock().lines().map_while(Result::ok) {
        let word = line.trim().to_lowercase();
        if word.is_empty() {
            continue;
        }

        // 4. Match word and write result directly to stdout
        let suggestions = symspell.lookup(&word, Verbosity::Closest, 2);
        let response = if suggestions.is_empty() {
            "MISSPELLED".to_string()
        } else if suggestions[0].term == word {
            "OK".to_string()
        } else {
            let list: Vec<String> = suggestions.iter().take(3).map(|s| s.term.clone()).collect();
            format!("SUGGESTIONS:{}", list.join(", "))
        };

        println!("{}", response);
        let _ = stdout.flush();
    }
}
