use std::str::FromStr;

pub fn parse_num<T: FromStr>(input: &str) -> Option<T> {
    input.parse::<T>().ok()
}

pub fn parse_bool(input: &str) -> Option<bool> {
    let first_char = input.chars().next()?.to_ascii_lowercase();
    match first_char {
        't' | 'y' | '1' => Some(true),
        'f' | 'n' | '0' => Some(false),
        _ => None
    }
}
