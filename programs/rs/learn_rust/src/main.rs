use std::io;

fn main() {

    println!("Type in your Celsius: ");

    let mut celsius = String::new();
    io::stdin().read_line(&mut celsius).unwrap();

    let celsius: f32 = celsius.trim().parse().unwrap();

    let fahrenheit: f32 = celsius * 9.0/5.0 + 32.0;

    println!("{} celcius converted to fahrenheit is: {:.1}", celsius, fahrenheit);

}
