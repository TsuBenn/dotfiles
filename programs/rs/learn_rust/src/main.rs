#[derive(Debug)]
struct Book {
    id: u32,
    title: String,
    author: String,
}

impl Book {
    fn new(id: u32, title: String, author: String) -> Book {
        Book {
            id: id,
            title: title,
            author: author,
        }
    }
}

fn main() {

    let a = Book::new(1, String::from("Harry Potter"), String::from("JK Rowling"));

    println!("{:?}", a);

}
