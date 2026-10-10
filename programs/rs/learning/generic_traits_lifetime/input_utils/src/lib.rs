mod parse;
mod reader;

use std::borrow::Cow;
use std::fmt::Display;
use std::str::FromStr;

pub use reader::read_bool as get_bool;
pub use reader::read_line as get_str;
pub use reader::read_num as get_num;

use crate::reader::ReaderError;

fn format_hint<'a>(prompt: &'a str, hint: &str) -> Cow<'a, str> {
    if prompt.contains("{}") {
        Cow::Owned(prompt.replace("{}", hint))
    } else {
        Cow::Borrowed(prompt)
    }
}

pub fn get_str_no_empty(prompt: &str) -> String {
    get_str_advanced(prompt, None)
}

pub fn get_str_with_default(prompt: &str, default_str: &str) -> String {
    get_str_advanced(prompt, Some(default_str))
}

pub fn get_str_advanced(prompt: &str, default_str: Option<&str>) -> String {
    let hint = match default_str {
        Some(s) => format!("[{}]", s),
        None => String::new(),
    };
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_str(prompt), default_str) {
            (Ok(s), _) => return s,
            (Err(ReaderError::Empty), Some(s)) => return s.to_string(),
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Something went wrong!"),
        }
    }
}

pub fn get_num_advanced<T>(
    prompt: &str,
    min: Option<T>,
    max: Option<T>,
    default_int: Option<T>,
) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    let mut hint: String = if min.is_none() && max.is_none() {
        String::new()
    } else {
        format!(
            "[{} - {}]",
            min.map_or("-inf".to_string(), |i| i.to_string()),
            max.map_or("inf".to_string(), |i| i.to_string())
        )
    };
    match default_int {
        Some(i) => hint = format!("{} [{}]", hint, i).trim().to_string(),
        _ => (),
    }
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_num(prompt), default_int) {
            (Ok(i), _) => {
                if match (min, max) {
                    (Some(min), Some(max)) => (min..=max).contains(&i),
                    (Some(min), None) => (min..).contains(&i),
                    (None, Some(max)) => (..=max).contains(&i),
                    (_, _) => true,
                } {
                    return i;
                } else {
                    println!("Out of bound! {}", hint)
                }
            }
            (Err(ReaderError::Empty), Some(i)) => return i,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid Number!"),
        }
    }
}

pub fn get_num_no_empty<T>(prompt: &str) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, None, None, None)
}

pub fn get_num_with_default<T>(prompt: &str, default_num: T) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, None, None, Some(default_num))
}

pub fn get_num_in_range<T>(prompt: &str, min: T, max: T) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, Some(min), Some(max), None)
}

pub fn get_bool_advanced(prompt: &str, default_bool: Option<bool>) -> bool {
    let hint = match default_bool {
        Some(s) => {
            if s {
                "[Y/n]"
            } else {
                "[y/N]"
            }
        }
        None => "[Y/N]",
    };
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_bool(prompt), default_bool) {
            (Ok(b), _) => return b,
            (Err(ReaderError::Empty), Some(b)) => return b,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid boolean!")
        }
    }
}

pub fn get_bool_no_empty(prompt: &str) -> bool {
    get_bool_advanced(prompt, None)
}

pub fn get_bool_with_default(prompt: &str, default_bool: bool) -> bool {
    get_bool_advanced(prompt, Some(default_bool))
}
