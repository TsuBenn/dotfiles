use std::io::{self, Write};

fn main() {
    let mut input = String::new();

    loop {
        print!("Enter a Celcius Value: ");
        io::stdout().flush().unwrap();
        io::stdin()
            .read_line(&mut input)
            .expect("Failed to read line");

        if input.trim().is_empty() {
            println!("This field cannot be left empty!")
        } else {
            break;
        }
    }

    let input = input.trim().parse().unwrap();

    println!(
        "You Celcius Value to Fahrenheit Value is: {}",
        c_to_f(input)
    );
    println!(
        "String from \"Hello World\" is: {}",
        String::from("Hello World")
    );
}

fn c_to_f(c: f32) -> f32 {
    c * (9.0 / 5.0) + 32.0
}
