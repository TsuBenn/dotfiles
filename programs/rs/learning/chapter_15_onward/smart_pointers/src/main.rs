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
                                    let next = cur.children.borrow().iter().find(|child| child.name == dir).map(Rc::clone);
                                    let Some(next) = next else {
                                        match_dir = false;
                                        continue;
                                    };
                                    match next.ntype {
                                        NodeType::File => {
                                            println!("Not a directory!");
                                            continue 'main;
                                        },
                                        NodeType::Directory => {
                                            cur = next;
                                            match_dir = true
                                        }
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
    name != "/" && !current_dir.children.borrow().iter().any(|child| child.name == name)
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
            if file == "/" {
                return Err("There can only be one root(/)!")
            }
            if file.contains("/") {
                return Err("Can't create file in inside of another dir. (Too lazy to implement!)")
            }
            return Ok(Command::Touch(file.to_owned()));
        }
        "mkdir" => {
            let Some(dir) = args.next() else {
                return Err("No directory name specified!");
            };
            if dir == "/" {
                return Err("There can only be one root(/)!")
            }
            if dir.contains("/") {
                return Err("Can't create directory in inside of another dir. (Too lazy to implement!)")
            }
            return Ok(Command::MakeDir(dir.to_owned()));
        }
        _ => Err("Invalid Command! Try \"ls\", \"cd\", \"touch\", \"mkdir\"."),
    }
}
