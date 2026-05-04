fn main() {

    let string = "Hello world!";

    let hello = &string[..5];
    let world = &string[6..];

    println!("{} {}", hello, world);

}
