use std::io::{self, Write};

use crate::input::parse::{parse_float, parse_int};

pub enum ReaderError {
    Empty,
    Err,
}

pub fn read_line(prompt: &str) -> Result<String, ReaderError> {
    let mut input = String::new();
    print!("{}", prompt);
    io::stdout().flush().expect("Stdout Flush failed!");
    io::stdin().read_line(&mut input).expect("Readline failed!");
    input = input.trim().to_string();
    if input.is_empty() {
        return Err(ReaderError::Empty);
    }
    return Ok(input);
}

pub fn read_int(prompt: &str) -> Result<i64, ReaderError> {
    let input = read_line(prompt);
    match input {
        Ok(input) => {
            match parse_int(&input) {
                Some(num) => return Ok(num),
                None => return Err(ReaderError::Empty)
            };
        }
        Err(err) => return Err(err)
    }
}

pub fn read_float(prompt: &str) -> Result<f64, ReaderError> {
    let input = read_line(prompt);
    match input {
        Ok(input) => {
            match parse_float(&input) {
                Some(num) => return Ok(num),
                None => return Err(ReaderError::Empty)
            };
        }
        Err(err) => return Err(err)
    }
}
