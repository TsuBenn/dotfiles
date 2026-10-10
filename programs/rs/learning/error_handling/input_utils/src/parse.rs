pub fn parse_int(input: &str) -> Option<i64> {
    input.parse().ok()
}

pub fn parse_float(input: &str) -> Option<f64> {
    input.parse().ok()
}
