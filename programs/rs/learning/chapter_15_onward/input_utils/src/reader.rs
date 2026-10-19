use std::{io::{self, Write}, str::FromStr};

use crate::parse::{parse_bool, parse_num};

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

pub fn read_num<T: FromStr>(prompt: &str) -> Result<T, ReaderError> {
    let input = read_line(prompt)?;
    parse_num::<T>(&input).ok_or(ReaderError::Err)
}

pub fn read_bool(prompt: &str) -> Result<bool, ReaderError> {
    let input = read_line(prompt)?;
    parse_bool(&input).ok_or(ReaderError::Err)
}
