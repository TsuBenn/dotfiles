use input_utils as input;

fn main() {
    let name = input::get_str_no_empty("Enter your name: ");
    let age = input::get_int_in_range("Enter your age {}: ", 1, 99);
    let gpa = input::get_float_in_range("Enter your GPA {}: ", 0.0, 4.0);

    println!();
    println!("So your name is {}, and you're {} years old.", name, age);
    println!("Looking at your record, apparently you have a GPA of {}", gpa);
}
