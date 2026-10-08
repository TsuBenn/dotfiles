use std::fs::File;

fn main() {
    let file = match File::open("hello.txt") {
        Ok(file) => file,
        Err(error) => panic!("\nError bro: {error}\n")
    };
}
