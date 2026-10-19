use input_utils as input;

fn main() {
    let name = input::get_str_no_empty("Enter your name: ");
    let major = input::get_str_with_default("Enter your Major {}: ", "CompSci");
    let age = input::get_num_in_range::<i64>("Enter your age {}: ", 1, 99);
    let gpa = input::get_num_in_range::<f64>("Enter your GPA {}: ", 0.0, 4.0);
    let gay = input::get_bool_no_empty("Are you gay? {}: ");

    println!();
    println!("So your name is {}, you're {} years old and major in {}", name, age, major);
    println!("Looking at your record, apparently you have a GPA of {}", gpa);
    println!("And also, you are {}.", if gay {"gay"} else {"not gay"});
}
