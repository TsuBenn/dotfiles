struct Book {
    title: String,
    author: String,
    is_available: bool,
}

struct MemberId(u64);

impl Book {
    fn new(title: &str, author: &str) -> Self {
        Book {
            title: title.to_string(),
            author: author.to_string(),
            is_available: true
        }
    }

    fn borrow_book(&mut self) -> bool {
        if self.is_available {
            self.is_available = false;
            true
        } else {
            false
        }
    }

    fn return_book(&mut self) {
        self.is_available = true;
    }

    fn summary(&self) -> String {
        format!("{} by {} [{}]", self.title, self.author, if self.is_available {"Available"} else {"Unavailable"})
    }

}

fn main() {

    let mut book1 = Book::new(
        "The Rust Programming Language",
        "Steve Klabnik"
    );

    let mut book2 = Book::new(
        "The C Programming Language",
       "Brian Kernighan and Dennis Ritchie"
    );

    let member = MemberId(90);
    let MemberId(id) = member;

    println!("Member ID is: {}", id);
    println!();

    println!("{}", book1.summary());
    println!("{}", book2.summary());
    println!();

    book1.borrow_book();
    book2.borrow_book();

    println!("{}", book1.summary());
    println!("{}", book2.summary());
    println!();

    book1.return_book();

    println!("{}", book1.summary());
    println!("{}", book2.summary());
    println!();

}
