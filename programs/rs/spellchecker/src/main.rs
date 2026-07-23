use std::collections::HashSet;
use std::io::{self, BufRead};

// Bake the dictionary into the binary at compile time.
// Make sure `words.txt` is in the same folder as main.rs!
const DICT_DATA: &str = include_str!("/usr/share/dict/words");

#[derive(Debug, PartialEq)]
enum DiffOp {
    Match(char),
    Replace(char, char), // (user_char, target_char)
    Delete(char),        // User typed an extra char
    Insert(char),        // User missed a char
}

// 1. Calculate character-by-character diffs using Levenshtein backtracking
fn diff_words(query: &str, target: &str) -> Vec<DiffOp> {
    let q_chars: Vec<char> = query.chars().collect();
    let t_chars: Vec<char> = target.chars().collect();
    let (m, n) = (q_chars.len(), t_chars.len());

    let mut dp = vec![vec![0; n + 1]; m + 1];

    for i in 0..=m {
        dp[i][0] = i;
    }
    for j in 0..=n {
        dp[0][j] = j;
    }

    for i in 1..=m {
        for j in 1..=n {
            if q_chars[i - 1] == t_chars[j - 1] {
                dp[i][j] = dp[i - 1][j - 1];
            } else {
                dp[i][j] = 1 + dp[i - 1][j - 1]
                    .min(dp[i - 1][j]) // Delete
                    .min(dp[i][j - 1]); // Insert
            }
        }
    }

    let mut ops = Vec::new();
    let (mut i, mut j) = (m, n);

    while i > 0 || j > 0 {
        if i > 0 && j > 0 && q_chars[i - 1] == t_chars[j - 1] {
            ops.push(DiffOp::Match(q_chars[i - 1]));
            i -= 1;
            j -= 1;
        } else if i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1 {
            ops.push(DiffOp::Replace(q_chars[i - 1], t_chars[j - 1]));
            i -= 1;
            j -= 1;
        } else if i > 0 && dp[i][j] == dp[i - 1][j.max(0)] + 1 {
            ops.push(DiffOp::Delete(q_chars[i - 1]));
            i -= 1;
        } else {
            ops.push(DiffOp::Insert(t_chars[j - 1]));
            j -= 1;
        }
    }

    ops.reverse();
    ops
}

// 2. Format diff ops with ANSI escape sequences
fn format_highlight(ops: &[DiffOp]) -> String {
    let mut out = String::new();

    for op in ops {
        match op {
            DiffOp::Match(c) => {
                // Green for matching characters
                out.push_str(&format!("\x1b[32m{}\x1b[0m", c));
            }
            DiffOp::Replace(user_c, target_c) => {
                // Red for wrong char, showing correct char in grey brackets
                out.push_str(&format!(
                    "\x1b[31;1m{}\x1b[0m\x1b[90m[{}]\x1b[0m",
                    user_c, target_c
                ));
            }
            DiffOp::Delete(user_c) => {
                // Strikethrough red for extra character
                out.push_str(&format!("\x1b[31;9m{}\x1b[0m", user_c));
            }
            DiffOp::Insert(target_c) => {
                // Dimmed grey bracket for missing character
                out.push_str(&format!("\x1b[90m[{}]\x1b[0m", target_c));
            }
        }
    }

    out
}

fn levenshtein(a: &str, b: &str) -> usize {
    let mut costs: Vec<usize> = (0..=b.len()).collect();
    for (i, ca) in a.chars().enumerate() {
        let mut last_diag = costs[0];
        costs[0] = i + 1;
        for (j, cb) in b.chars().enumerate() {
            let old_diag = last_diag;
            last_diag = costs[j + 1];
            costs[j + 1] = if ca == cb {
                old_diag
            } else {
                1 + old_diag.min(costs[j + 1]).min(costs[j])
            };
        }
    }
    costs[b.len()]
}

fn common_prefix_len(a: &str, b: &str) -> usize {
    a.chars()
        .zip(b.chars())
        .take_while(|(ca, cb)| ca == cb)
        .count()
}

fn main() {
    let dict: HashSet<String> = DICT_DATA
        .lines()
        .map(|line| line.trim().to_lowercase())
        .collect();

    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        if let Ok(word) = line {
            let query = word.trim().to_lowercase();
            if query.is_empty() {
                continue;
            }

            if dict.contains(&query) {
                println!("*");
            } else {
                let mut candidates: Vec<(i32, &str)> = DICT_DATA
                    .lines()
                    .filter_map(|w| {
                        let lower_w = w.to_lowercase();

                        let len_diff = lower_w.len().abs_diff(query.len());
                        if len_diff > 3 && !lower_w.starts_with(&query) {
                            return None;
                        }

                        let dist = levenshtein(&query, &lower_w);
                        let prefix_len = common_prefix_len(&query, &lower_w);

                        if dist <= 2 || prefix_len >= 3 {
                            let score = (dist as i32 * 10) - (prefix_len as i32);
                            Some((score, w))
                        } else {
                            None
                        }
                    })
                    .collect();

                candidates.sort_by_key(|(score, _)| *score);

                if candidates.is_empty() {
                    println!("#");
                } else {
                    // Map EVERY candidate to a highlighted string
                    let highlighted_suggestions: Vec<String> = candidates
                        .into_iter()
                        .take(5)
                        .map(|(_, w)| {
                            let ops = diff_words(&query, &w.to_lowercase());
                            format_highlight(&ops)
                        })
                        .collect();

                    println!("{}", highlighted_suggestions.join(" "));
                }
            }
        }
    }
}
