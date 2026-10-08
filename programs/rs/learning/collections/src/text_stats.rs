use std::collections::HashMap;

pub struct TextStats {
    pub total_words: usize,
    pub unique_words: usize,
    pub avg_word_len: f64,
    pub median_word_len: f64,
    pub word_freq: HashMap<String,usize>,
    pub char_freq: Vec<(char, usize)>,
}

pub fn analyze_sentence(sentence: &str) -> TextStats {

    let mut word_letter_counts: Vec<u32> = Vec::new();

    let total_letters = sentence.chars().filter(|c| !c.is_whitespace()).count();

    let mut word_map: HashMap<String, usize> = HashMap::new();
    let mut letter_map: HashMap<char, usize> = HashMap::new();
    let mut letter_tuples: Vec<(char, usize)> = Vec::new();

    for word in sentence.split_whitespace() {
        let word_count = word_map.entry(word.to_string().to_lowercase()).or_insert(0);
        *word_count += 1;
        for c in word.to_lowercase().chars() {
            let letter_count = letter_map.entry(c).or_insert(0);
            *letter_count += 1;
        }
        word_letter_counts.push(word.len() as u32)
    }

    let total_words = word_letter_counts.len();
    word_letter_counts.sort();

    let mut median_word_len: f64 = word_letter_counts[(total_words-1)/2] as f64;
    if total_words%2==0 {
         median_word_len = (word_letter_counts[total_words/2] + word_letter_counts[total_words/2 - 1]) as f64 / 2.0;
    }

    for (&letter, &count) in &letter_map {
        letter_tuples.push((letter, count))
    }

    letter_tuples.sort_by(|a, b| b.1.cmp(&a.1));

    TextStats {
        total_words,
        unique_words: word_map.len(),
        avg_word_len: (total_letters as f64)/(total_words as f64),
        median_word_len,
        word_freq: word_map,
        char_freq: letter_tuples,
    }
}
