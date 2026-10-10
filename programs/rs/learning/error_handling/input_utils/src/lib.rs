mod parse;
mod reader;

pub use reader::read_float as get_float;
pub use reader::read_int as get_int;
pub use reader::read_line as get_str;

use crate::reader::ReaderError;

pub fn get_str_no_empty(prompt: &str) -> String {
    get_str_advanced(prompt, None)
}

pub fn get_str_with_default(prompt: &str, default_str: &str) -> String {
    get_str_advanced(prompt, Some(default_str))
}

pub fn get_str_advanced(prompt: &str, default_str: Option<&str>) -> String {
    let hint = match default_str {
        Some(s) => &format!(" [{}]", s),
        None => "",
    };
    let prompt = &format!("{}{}", prompt, hint);
    loop {
        match (get_str(prompt), default_str) {
            (Ok(s), _) => return s,
            (Err(ReaderError::Empty), Some(s)) => return s.to_string(),
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Something went wrong!"),
        }
    }
}

pub fn get_int_advanced(prompt: &str, min: Option<i64>, max: Option<i64>, default_int: Option<i64>) -> i64 {
    let mut hint: String = if min == None && max == None {
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
    let prompt = if prompt.contains("{}") {
        &prompt.replace("{}", &hint)
    } else {
        prompt
    };
    loop {
        match (get_int(prompt), default_int) {
            (Ok(i), _) => {
                let max = max.unwrap_or(i64::MAX);
                let min = min.unwrap_or(i64::MIN);
                if !(min..=max).contains(&i) {
                    println!("Out of bound! {}", hint);
                    continue;
                }
                return i;
            }
            (Err(ReaderError::Empty), Some(i)) => return i,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid Integer!"),
        }
    }
}

pub fn get_int_no_empty(prompt: &str) -> i64 {
    get_int_advanced(prompt, None, None, None)
}

pub fn get_int_with_default(prompt: &str, default_int: i64) -> i64 {
    get_int_advanced(prompt, None, None, Some(default_int))
}

pub fn get_int_in_range(prompt: &str, min: i64, max: i64) -> i64 {
    get_int_advanced(prompt, Some(min), Some(max), None)
}

pub fn get_float_advanced(prompt: &str, min: Option<f64>, max: Option<f64>, default_float: Option<f64>) -> f64 {
    let mut hint: String = if min == None && max == None {
        String::new()
    } else {
        format!(
            "[{} - {}]",
            min.map_or("-inf".to_string(), |i| i.to_string()),
            max.map_or("inf".to_string(), |i| i.to_string())
        )
    };
    match default_float {
        Some(i) => hint = format!("{} [{}]", hint, i).trim().to_string(),
        _ => (),
    }
    let prompt = if prompt.contains("{}") {
        &prompt.replace("{}", &hint)
    } else {
        prompt
    };
    loop {
        match (get_float(prompt), default_float) {
            (Ok(i), _) => {
                let max = max.unwrap_or(f64::MAX);
                let min = min.unwrap_or(f64::MIN);
                if !(min..=max).contains(&i) {
                    println!("Out of bound! {}", hint);
                    continue;
                }
                return i;
            }
            (Err(ReaderError::Empty), Some(i)) => return i,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid Float!"),
        }
    }
}

pub fn get_float_no_empty(prompt: &str) -> f64 {
    get_float_advanced(prompt, None, None, None)
}

pub fn get_float_with_default(prompt: &str, default_float: f64) -> f64 {
    get_float_advanced(prompt, None, None, Some(default_float))
}

pub fn get_float_in_range(prompt: &str, min: f64, max: f64) -> f64 {
    get_float_advanced(prompt, Some(min), Some(max), None)
}
