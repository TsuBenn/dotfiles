use std::{env, error::Error, fs, process};

use minigrep::{search, search_case_insensitive};

fn main() {
    let args: Vec<String> = env::args().collect();

    let config = Config::new(&args).unwrap_or_else(|err| {
        eprintln!("Problem parsing arguments: {err}");
        process::exit(1);
    });

    if let Err(e) = run(config) {
        eprintln!("Application error: {e}");
        process::exit(1);
    }
}

struct Config {
    query: String,
    filename: String,
    case_insensitive: bool
}

impl Config {
    fn new(args: &[String]) -> Result<Config, &'static str> {
        if args.len() < 3 {
            return Err("not enough arguments");
        }
        let query = args[1].clone();
        let filename = args[2].clone();
        let case_insensitive = args.get(3).map_or(false, |s| s == "-i");

        Ok(Config {query, filename, case_insensitive})
    }
}

fn run(config: Config) -> Result<(),Box<dyn Error>> {
    let content = fs::read_to_string(config.filename)?;

    let result = if config.case_insensitive {
        search_case_insensitive(&config.query, &content)
    } else {
        search(&config.query, &content)
    };

    for line in result {
        println!("{line}")
    }

    Ok(())
}
