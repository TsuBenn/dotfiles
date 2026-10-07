use std::io::{self, Write};

struct Task {
    id: u64,
    description: String,
    is_completed: bool,
}

enum Command {
    Add(String),
    Complete(u64),
    Delete(u64),
    List(StatusFilter),
    Help,
    Quit,
}

enum StatusFilter {
    All,
    CompletedOnly,
    PendingOnly,
}

fn main() {
    let mut tasks: Vec<Task> = Vec::new();
    let mut next_id: u64 = 0;

    loop {
        let mut input = String::new();
        print!("> ");
        io::stdout().flush().unwrap();

        if io::stdin().read_line(&mut input).is_err() || input.is_empty() {
            println!("Input shall not be empty!");
            println!();
            continue;
        }

        let Some(cmd) = parse_command(&input) else {
            println!("Invalid command! Type \"help\" to see available commands.");
            println!();
            continue;
        };
        match cmd {
            Command::Add(description) => {
                let new_task = Task {
                    id: next_id,
                    description: description,
                    is_completed: false
                };
                tasks.push(new_task);
                next_id += 1;
            }
            Command::Complete(id) => {
                match find_task_mut(&mut tasks, id) {
                    Some(task) => {
                        task.is_completed = true
                    }
                    _ => {
                        println!("Task of id {} is not found!", id)
                    }
                }
            }
            Command::Delete(id) => {
                tasks.retain(|task| task.id != id);
            }
            Command::List(filter) => {
                print_task_header();
                let mut printed = false;
                for task in tasks.iter() {
                    match filter {
                        StatusFilter::All => {print_task(&task); printed = true},
                        StatusFilter::PendingOnly if !task.is_completed => {print_task(&task); printed = true},
                        StatusFilter::CompletedOnly if task.is_completed => {print_task(&task); printed = true},
                        _ => {}
                    }
                }
                if !printed {
                    print_task_empty();
                    print_task_footer();
                }
            }
            Command::Help => {
                print_help();
            }
            Command::Quit => {
                break
            }
        }

        println!()
    }
}

fn print_task_header() {
    println!("+------------------------------------------------------+");
    println!("|                        TASKS                         |");
    println!("+------------------------------------------------------+");
}

fn print_task_empty() {
    println!("|                 No Tasks Available!                  |");
}

fn print_task_footer() {
    println!("+------------------------------------------------------+");
}

fn print_help() {
    println!("+------------------------------------------------------+");
    println!("|                  LISTS OF COMMANDS                   |");
    println!("+------------------------------------------------------+");
    println!("| help                    -> Print this table          |");
    println!("| list                    -> List all tasks            |");
    println!("| list     <done|pending> -> List tasks with filter    |");
    println!("| add      <description>  -> Add a task                |");
    println!("| delete   <id>           -> Delete a task using ID    |");
    println!("| complete <id>           -> Complete a task using ID  |");
    println!("+------------------------------------------------------+");
}

fn print_task(task: &Task) {
    println!("| ID: {}", task.id);
    println!("| Description: {}", task.description);
    println!("| Completed: {}", if task.is_completed {"Done"} else {"Pending"});
    print_task_footer();
}

fn parse_command(input: &str) -> Option<Command> {
    let input = input.trim();
    let Some((cmd, arg)) = input.split_once(char::is_whitespace) else {
        match input {
            "list" => return Some(Command::List(StatusFilter::All)),
            "help" => return Some(Command::Help),
            "quit" => return Some(Command::Quit),
            _ => return None,
        }
    };

    match cmd {
        "add" => Some(Command::Add(arg.trim().to_string())),
        "complete" => {
            let Ok(id) = arg.parse() else {
                return None;
            };
            Some(Command::Complete(id))
        }
        "delete" => {
            let Ok(id) = arg.parse() else {
                return None;
            };
            Some(Command::Delete(id))
        }
        "list" => match arg {
            "done" => Some(Command::List(StatusFilter::CompletedOnly)),
            "pending" => Some(Command::List(StatusFilter::PendingOnly)),
            _ => None,
        },
        _ => None,
    }
}

fn find_task_mut(tasks: &mut [Task], id: u64) -> Option<&mut Task> {
    for task in tasks {
        if task.id == id {
            return Some(task);
        }
    }
    None
}
