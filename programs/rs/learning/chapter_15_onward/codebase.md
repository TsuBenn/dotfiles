This file is a merged representation of the entire codebase, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
input_utils/
  src/
    lib.rs
    main.rs
    parse.rs
    reader.rs
  Cargo.toml
smart_pointers/
  src/
    main.rs
  Cargo.toml
.gitignore
Cargo.toml
```

# Files

## File: input_utils/src/lib.rs
```rust
mod parse;
mod reader;

use std::borrow::Cow;
use std::fmt::Display;
use std::str::FromStr;


pub use reader::read_bool as get_bool;
pub use reader::read_line as get_str;
pub use reader::read_num as get_num;

pub use crate::reader::ReaderError;

fn format_hint<'a>(prompt: &'a str, hint: &str) -> Cow<'a, str> {
    if prompt.contains("{}") {
        Cow::Owned(prompt.replace("{}", hint))
    } else {
        Cow::Borrowed(prompt)
    }
}

pub fn get_str_no_empty(prompt: &str) -> String {
    get_str_advanced(prompt, None)
}

pub fn get_str_with_default(prompt: &str, default_str: &str) -> String {
    get_str_advanced(prompt, Some(default_str))
}

pub fn get_str_advanced(prompt: &str, default_str: Option<&str>) -> String {
    let hint = match default_str {
        Some(s) => format!("[{}]", s),
        None => String::new(),
    };
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_str(prompt), default_str) {
            (Ok(s), _) => return s,
            (Err(ReaderError::Empty), Some(s)) => return s.to_string(),
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Something went wrong!"),
        }
    }
}

pub fn get_num_advanced<T>(
    prompt: &str,
    min: Option<T>,
    max: Option<T>,
    default_int: Option<T>,
) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    let mut hint: String = if min.is_none() && max.is_none() {
        String::new()
    } else {
        format!(
            "[{} - {}]",
            min.map_or("-inf".to_string(), |i| i.to_string()),
            max.map_or("inf".to_string(), |i| i.to_string())
        )
    };
    match default_int {
        Some(i) => hint = format!("{} [{}]", hint, i).trim().to_string(),
        _ => (),
    }
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_num(prompt), default_int) {
            (Ok(i), _) => {
                if match (min, max) {
                    (Some(min), Some(max)) => (min..=max).contains(&i),
                    (Some(min), None) => (min..).contains(&i),
                    (None, Some(max)) => (..=max).contains(&i),
                    (_, _) => true,
                } {
                    return i;
                } else {
                    println!("Out of bound! {}", hint)
                }
            }
            (Err(ReaderError::Empty), Some(i)) => return i,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid Number!"),
        }
    }
}

pub fn get_num_no_empty<T>(prompt: &str) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, None, None, None)
}

pub fn get_num_with_default<T>(prompt: &str, default_num: T) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, None, None, Some(default_num))
}

pub fn get_num_in_range<T>(prompt: &str, min: T, max: T) -> T
where
    T: FromStr + Copy + PartialOrd + Display,
{
    get_num_advanced(prompt, Some(min), Some(max), None)
}

pub fn get_bool_advanced(prompt: &str, default_bool: Option<bool>) -> bool {
    let hint = match default_bool {
        Some(s) => {
            if s {
                "[Y/n]"
            } else {
                "[y/N]"
            }
        }
        None => "[Y/N]",
    };
    let prompt = &format_hint(prompt, &hint);
    loop {
        match (get_bool(prompt), default_bool) {
            (Ok(b), _) => return b,
            (Err(ReaderError::Empty), Some(b)) => return b,
            (Err(ReaderError::Empty), None) => println!("This field cannot be empty!"),
            (Err(_), _) => println!("Invalid boolean!")
        }
    }
}

pub fn get_bool_no_empty(prompt: &str) -> bool {
    get_bool_advanced(prompt, None)
}

pub fn get_bool_with_default(prompt: &str, default_bool: bool) -> bool {
    get_bool_advanced(prompt, Some(default_bool))
}
```

## File: input_utils/src/main.rs
```rust
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
```

## File: input_utils/src/parse.rs
```rust
use std::str::FromStr;

pub fn parse_num<T: FromStr>(input: &str) -> Option<T> {
    input.parse::<T>().ok()
}

pub fn parse_bool(input: &str) -> Option<bool> {
    let first_char = input.chars().next()?.to_ascii_lowercase();
    match first_char {
        't' | 'y' | '1' => Some(true),
        'f' | 'n' | '0' => Some(false),
        _ => None
    }
}
```

## File: input_utils/src/reader.rs
```rust
use std::{io::{self, Write}, str::FromStr};

use crate::parse::{parse_bool, parse_num};

pub enum ReaderError {
    Empty,
    Err,
}

pub fn read_line(prompt: &str) -> Result<String, ReaderError> {
    let mut input = String::new();
    print!("{}", prompt);
    io::stdout().flush().map_err(|_| ReaderError::Err)?;
    io::stdin().read_line(&mut input).map_err(|_| ReaderError::Err)?;
    input = input.trim().to_string();
    if input.is_empty() {
        return Err(ReaderError::Empty);
    }
    Ok(input)
}

pub fn read_num<T: FromStr>(prompt: &str) -> Result<T, ReaderError> {
    let input = read_line(prompt)?;
    parse_num::<T>(&input).ok_or(ReaderError::Err)
}

pub fn read_bool(prompt: &str) -> Result<bool, ReaderError> {
    let input = read_line(prompt)?;
    parse_bool(&input).ok_or(ReaderError::Err)
}
```

## File: input_utils/Cargo.toml
```toml
[package]
name = "input_utils"
version = "0.1.0"
edition = "2024"

[dependencies]
```

## File: smart_pointers/src/main.rs
```rust
use std::{
    cell::RefCell, rc::{Rc, Weak}
};

use input_utils::*;

enum NodeType {
    File,
    Directory,
}

struct Node {
    name: String,
    ntype: NodeType,
    parent: RefCell<Weak<Node>>,
    children: RefCell<Vec<Rc<Node>>>,
}

enum Command {
    List,
    ChangeDir(Vec<String>),
    Touch(String),
    MakeDir(String),
}

fn main() {
    let root = Rc::new(Node {
        name: "/".to_owned(),
        ntype: NodeType::Directory,
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(vec![]),
    });

    let mut current_dir = Rc::clone(&root);

    println!("----------------------------------------------------");
    println!("          Welcome to a Virtual File System          ");
    println!("----------------------------------------------------");

    'main: loop {
        let Ok(input) = get_str("> ") else {
            continue;
        };

        match parse_args(&input) {
            Ok(cmd) => match cmd {
                Command::List => {
                    if !check_current_dir(&mut current_dir, &root) {
                        continue;
                    }
                    println!("Current dir: {}", current_dir.name);
                    println!(".");
                    if current_dir.name != "/" {
                        println!("..")
                    }
                    for child in current_dir.children.borrow().iter() {
                        match child.ntype {
                            NodeType::File => println!("{}", child.name),
                            NodeType::Directory => println!("{}/", child.name),
                        }
                    }
                }
                Command::ChangeDir(dirs) => match current_dir.ntype {
                    NodeType::File => {
                        check_current_dir(&mut current_dir, &root);
                        continue;
                    }
                    NodeType::Directory => {
                        let mut cur = Rc::clone(&current_dir);
                        let mut match_dir = false;
                        for dir in dirs {
                            match &dir[..] {
                                "." => continue,
                                ".." => {
                                    if cur.name == "/" {
                                        println!("Already at root(/)!");
                                        continue 'main;
                                    }
                                    let Some(parent) = cur.parent.borrow().upgrade() else {
                                        println!("Error: This dir has no parent!?");
                                        println!("       Changing dir back to root(/).");
                                        current_dir = Rc::clone(&root);
                                        continue;
                                    };
                                    cur = parent;
                                    match_dir = true;
                                    continue;
                                }
                                _ => {
                                    let mut next = None;
                                    for child in cur.children.borrow().iter() {
                                        if child.name == dir {
                                            match child.ntype {
                                                NodeType::File => {
                                                    println!("Not a directory!");
                                                    continue 'main;
                                                }
                                                NodeType::Directory => {
                                                    next = Some(Rc::clone(child));
                                                    match_dir = true;
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    match next {
                                        Some(next) => cur = next,
                                        None => match_dir = false
                                    }
                                }
                            }
                        }
                        match match_dir {
                            true => { println!("* Changed directory to: {}", cur.name); current_dir = cur;},
                            false => println!("No directory found!"),
                        }
                    }
                },
                Command::Touch(name) => {
                    if !check_current_dir(&mut current_dir, &root) {
                        continue;
                    }
                    if !check_name_availability(&current_dir, &name) {
                        println!("Name has already been taken! Try something else.");
                        continue;
                    }
                    println!("* Create a file: {}", &name);
                    current_dir.children.borrow_mut().push(Rc::new(Node {
                        name,
                        ntype: NodeType::File,
                        parent: RefCell::new(Rc::downgrade(&current_dir)),
                        children: RefCell::new(vec![]),
                    }));
                }
                Command::MakeDir(name) => {
                    if !check_current_dir(&mut current_dir, &root) {
                        continue;
                    }
                    if !check_name_availability(&current_dir, &name) {
                        println!("Name has already been taken! Try something else.");
                        continue;
                    }
                    println!("* Create a directory: {}", &name);
                    current_dir.children.borrow_mut().push(Rc::new(Node {
                        name,
                        ntype: NodeType::Directory,
                        parent: RefCell::new(Rc::downgrade(&current_dir)),
                        children: RefCell::new(vec![]),
                    }));
                }
            },
            Err(e) => {
                println!("Error: {e}");
                continue;
            }
        }
    }
}

fn check_current_dir(current_dir: &mut Rc<Node>, root: &Rc<Node>) -> bool {
    match current_dir.ntype {
        NodeType::File => {
            println!("Error: How are you even in a file!?");
            println!("       Changing dir back to root(/).");
            *current_dir = Rc::clone(root);
            false
        }
        _ => true,
    }
}

fn check_name_availability(current_dir: &Rc<Node>, name: &str) -> bool {
    if name == "/" {
        return false;
    }
    for child in current_dir.children.borrow().iter() {
        if child.name == name {
            return false;
        }
    }
    return true;
}

fn parse_args(input: &str) -> Result<Command, &str> {
    let mut args = input.split_whitespace();
    match args.next().ok_or("Empty")? {
        "ls" => Ok(Command::List),
        "cd" => {
            let Some(dir) = args.next() else {
                return Err("No directory name specified!");
            };
            let dirs = dir.split("/").map(|s| s.to_string()).collect();
            Ok(Command::ChangeDir(dirs))
        }
        "touch" => {
            let Some(file) = args.next() else {
                return Err("No name specified!");
            };
            if file.contains("/") {
                return Err("Can't create file in inside of another dir. (Too lazy to implement!)")
            }
            return Ok(Command::Touch(file.to_owned()));
        }
        "mkdir" => {
            let Some(dir) = args.next() else {
                return Err("No directory name specified!");
            };
            if dir.contains("/") {
                return Err("Can't create directory in inside of another dir. (Too lazy to implement!)")
            }
            return Ok(Command::MakeDir(dir.to_owned()));
        }
        _ => Err("Invalid Command! Try \"ls\", \"cd\", \"touch\", \"mkdir\"."),
    }
}
```

## File: smart_pointers/Cargo.toml
```toml
[package]
name = "smart_pointers"
version = "0.1.0"
edition = "2024"

[dependencies]
input_utils = { path = "../input_utils"}
```

## File: .gitignore
```
/target/
```

## File: Cargo.toml
```toml
[workspace]
resolver = "3"
members = ["input_utils", "smart_pointers"]
```
