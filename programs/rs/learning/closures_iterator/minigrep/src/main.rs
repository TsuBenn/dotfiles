use std::{env, error::Error, fs, process};

use minigrep::{search, search_case_insensitive};

fn main() {
    let config = Config::build(env::args()).unwrap_or_else(|err| {
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
    file_path: String,
    case_insensitive: bool
}

impl Config {
    fn build(mut args: impl Iterator<Item = String>) -> Result<Config, &'static str> {

        args.next();

        let Some(query) = args.next() else {
            return Err("No query provided.");
        };

        let Some(file_path) = args.next() else {
            return Err("No file path provided.");
        };

        let mut case_insensitive = false;

        for arg in args {
            if arg == "-i" {
                case_insensitive = true;
            }
        }

        Ok(Config {query, file_path, case_insensitive})
    }
}

fn run(config: Config) -> Result<(),Box<dyn Error>> {
    let content = fs::read_to_string(config.file_path)?;

    if config.case_insensitive {
        for line in search_case_insensitive(&config.query, &content) {
            println!("{line}")
        }
    } else {
        for line in search(&config.query, &content) {
            println!("{line}")
        }
    }

    Ok(())
}
