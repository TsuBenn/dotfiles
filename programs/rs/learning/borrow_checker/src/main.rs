use std::io::{self, Write};

fn main() {

    let mut input = String::new();

    print!("Enter a sentence: ");
    io::stdout().flush().unwrap();

    io::stdin().read_line(&mut input).unwrap();

    let input = input.trim();

    println!();

    println!("First word: {}", first_word(input));
    println!("Words count: {}", words_count(input));
    println!("Characters count: {}", input.len());
    println!("Sentence itself: \"{}\"", input);

}

fn first_word(s: &str) -> &str {
    for (i, c) in s.char_indices() {
        if c == ' ' {
            return &s[..i];
        }
    }
    s
}

fn words_count(s: &str) -> i32 {
    let mut count = 0;
    let mut in_word = false;
    for (_, c) in s.char_indices() {
        if c != ' ' && !in_word {
            in_word = true;
            count += 1;
        } else if c == ' ' {
            in_word = false;
        }
    }
    count
}
