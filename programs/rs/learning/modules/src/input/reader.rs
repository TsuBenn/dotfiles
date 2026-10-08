use std::io::{self, Write};

use crate::input::parse::{parse_float, parse_int};

pub enum StrResult {
    Ok(String),
    Empty,
    Err,
}

pub enum IntResult {
    Ok(i64),
    Empty,
    Err,
}

pub enum FloatResult {
    Ok(f64),
    Empty,
    Err,
}

pub fn read_line(prompt: &str) -> StrResult {
    let mut input = String::new();
    print!("{}", prompt);
    io::stdout().flush().expect("Stdout Flush failed!");
    io::stdin().read_line(&mut input).expect("Readline failed!");
    input = input.trim().to_string();
    if input.is_empty() {
        return StrResult::Empty;
    }
    return StrResult::Ok(input);
}

pub fn read_int(prompt: &str) -> IntResult {
    let input = read_line(prompt);
    match input {
        StrResult::Ok(input) => {
            let Some(num) = parse_int(&input) else {
                return IntResult::Err;
            };
            return IntResult::Ok(num);
        }
        StrResult::Empty => return IntResult::Empty,
        StrResult::Err => return IntResult::Err
    }
}

pub fn read_float(prompt: &str) -> FloatResult {
    let input = read_line(prompt);
    match input {
        StrResult::Ok(input) => {
            let Some(num) = parse_float(&input) else {
                return FloatResult::Err;
            };
            return FloatResult::Ok(num);
        }
        StrResult::Empty => return FloatResult::Empty,
        StrResult::Err => return FloatResult::Err
    }
}
