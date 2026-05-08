
pub struct NewsArticle {
    pub author: String,
    pub headline: String,
    pub content: String,
}

pub struct Tweet {
    pub username: String,
    pub content: String,
    pub reply: bool,
    pub retweet: bool,
}

impl Summary for NewsArticle {
    fn summary(&self) -> String {
        format!("{}, by {}", self.headline, self.author)
    }
}

impl Summary for Tweet {
    fn summary(&self) -> String {
        format!("{}, by {}", self.content, self.username)
    }
}

pub trait Summary {
    fn summary(&self) -> String;
}

fn main() {

    let tweet = Tweet {
        username: String::from("TsuBenn"),
        content: String::from("Rust be ballin'"),
        reply: false,
        retweet: false,
    };

    let news = NewsArticle {
        author: String::from("TwoBenn"),
        headline: String::from("Rust is not good"),
        content: String::from("JK, Rust be ballin'"),
    };

    println!("{}",tweet.summary());
    println!("{}",news.summary());

}
