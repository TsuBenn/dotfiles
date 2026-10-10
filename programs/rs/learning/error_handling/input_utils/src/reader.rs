use std::io::{self, Write};

use crate::parse::{parse_float, parse_int};

pub enum ReaderError {
    Empty,
    Err,
}

pub fn read_line(prompt: &str) -> Result<String, ReaderError> {
    let mut input = String::new();
    print!("{}", prompt);
    io::stdout().flush().map_err(|_| ReaderError::Err)?;
    io::stdin().read_line(&mut input).map_err(|_| ReaderError::Err)?;
    input = input.trim().to_string();
    if input.is_empty() {
        return Err(ReaderError::Empty);
    }
    Ok(input)
}

pub fn read_int(prompt: &str) -> Result<i64, ReaderError> {
    let input = read_line(prompt)?;
    parse_int(&input).ok_or(ReaderError::Err)
}

pub fn read_float(prompt: &str) -> Result<f64, ReaderError> {
    let input = read_line(prompt)?;
    parse_float(&input).ok_or(ReaderError::Err)
}
