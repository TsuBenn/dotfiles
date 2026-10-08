use input_utils::input;

use crate::text_stats::{TextStats, analyze_sentence};

mod pig_latin;
mod text_stats;

fn main() {
    loop {
        println!("==== Text Analyzer & Pig Latin Converter ====");

        let input = input::get_str_no_empty("Enter a paragraph or sentence:\n> ");

        println!("\n---- Pig Latin Output ----");
        println!("{}", pig_latin::convert(&input));

        let text_stats: TextStats = analyze_sentence(&input);

        println!("\n---- Text Statistics ----");
        println!("Total word: {}", text_stats.total_words);
        println!("Unique word: {}", text_stats.unique_words);
        println!("Average word length: {:.2}", text_stats.avg_word_len);
        println!("Median Word Length: {:.2}", text_stats.median_word_len);

        println!("\n---- Word frequency ----");
        for (word, count) in &text_stats.word_freq {
            println!("\"{}\": {}", word, count);
        }

        println!("\n---- Character frequency (Top 3) ----");
        let top_count = text_stats.char_freq.len().min(3);
        for (word, count) in &text_stats.char_freq[..top_count] {
            println!("\"{}\": {}", word, count);
        }

        println!();
    }
}
