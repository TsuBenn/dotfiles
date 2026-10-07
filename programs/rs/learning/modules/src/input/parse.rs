pub fn parse_int(input: &str) -> Option<i64> {
    match input.parse() {
        Ok(i) => Some(i),
        _ => None
    }
}

pub fn parse_float(input: &str) -> Option<f64> {
    match input.parse() {
        Ok(i) => Some(i),
        _ => None
    }
}
