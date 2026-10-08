const VOWELS: [char; 5] = ['a','i','u','e','o'];
const CLUSTERS: [&str; 14] = [
    "th", "br", "bl", "cl", "cr",
    "dr", "fl", "fr", "gr", "pl",
    "pr", "st", "tr", "qu"
];

pub fn convert(input: &str) -> String {
    let mut words: Vec<String> = Vec::new();
    for word in input.split_whitespace() {
        if word.starts_with(&VOWELS) {
            words.push(format!("{}-hay",word));
        } else {
            let mut word = word.to_owned();
            let mut consonant: String = word.remove(0).to_string();
            if let Some(next_char) = word.chars().next() {
                let candidate = format!("{}{}", consonant, next_char);
                if CLUSTERS.contains(&candidate.as_str()) {
                    consonant.push(word.remove(0));
                }
            }
            words.push(format!("{}-{}ay", capitalize(&word), consonant.to_lowercase()));
        }
    }
    words.join(" ")
}

fn capitalize(str: &str) -> String {
    let mut chars = str.chars();
    match chars.next() {
        None => String::new(),
        Some(first) => format!("{}{}", first.to_uppercase(), chars.as_str().to_lowercase())
    }
}
