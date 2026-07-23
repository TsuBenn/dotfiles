use std::collections::{HashMap, HashSet};
use std::io::{self, BufRead};

const DICT_DATA: &str = include_str!("../words.txt");

#[derive(Debug, PartialEq)]
enum DiffOp {
    Match(char),
    Replace(char, char),
    Delete(char),
    Insert(char),
    Transpose(char, char), // (target_first, target_second)
}

// Damerau-Levenshtein distance only (fast, no backtrack table needed)
fn damerau_distance(a: &str, b: &str) -> usize {
    let a_chars: Vec<char> = a.chars().collect();
    let b_chars: Vec<char> = b.chars().collect();
    let (m, n) = (a_chars.len(), b_chars.len());

    let mut dp = vec![vec![0; n + 1]; m + 1];
    for i in 0..=m {
        dp[i][0] = i;
    }
    for j in 0..=n {
        dp[0][j] = j;
    }

    for i in 1..=m {
        for j in 1..=n {
            let cost = if a_chars[i - 1] == b_chars[j - 1] {
                0
            } else {
                1
            };
            dp[i][j] = (dp[i - 1][j] + 1)
                .min(dp[i][j - 1] + 1)
                .min(dp[i - 1][j - 1] + cost);

            if i > 1
                && j > 1
                && a_chars[i - 1] == b_chars[j - 2]
                && a_chars[i - 2] == b_chars[j - 1]
            {
                dp[i][j] = dp[i][j].min(dp[i - 2][j - 2] + 1);
            }
        }
    }
    dp[m][n]
}

// Same recurrence, but keeps the full table so we can backtrack for highlighting
fn diff_words(query: &str, target: &str) -> Vec<DiffOp> {
    let q: Vec<char> = query.chars().collect();
    let t: Vec<char> = target.chars().collect();
    let (m, n) = (q.len(), t.len());

    let mut dp = vec![vec![0; n + 1]; m + 1];
    for i in 0..=m {
        dp[i][0] = i;
    }
    for j in 0..=n {
        dp[0][j] = j;
    }

    for i in 1..=m {
        for j in 1..=n {
            let cost = if q[i - 1] == t[j - 1] { 0 } else { 1 };
            dp[i][j] = (dp[i - 1][j] + 1)
                .min(dp[i][j - 1] + 1)
                .min(dp[i - 1][j - 1] + cost);

            if i > 1 && j > 1 && q[i - 1] == t[j - 2] && q[i - 2] == t[j - 1] {
                dp[i][j] = dp[i][j].min(dp[i - 2][j - 2] + 1);
            }
        }
    }

    let mut ops = Vec::new();
    let (mut i, mut j) = (m, n);

    while i > 0 || j > 0 {
        if i > 0 && j > 0 && q[i - 1] == t[j - 1] {
            ops.push(DiffOp::Match(q[i - 1]));
            i -= 1;
            j -= 1;
        } else if i > 1
            && j > 1
            && q[i - 1] == t[j - 2]
            && q[i - 2] == t[j - 1]
            && dp[i][j] == dp[i - 2][j - 2] + 1
        {
            ops.push(DiffOp::Transpose(t[j - 2], t[j - 1]));
            i -= 2;
            j -= 2;
        } else if i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1 {
            ops.push(DiffOp::Replace(q[i - 1], t[j - 1]));
            i -= 1;
            j -= 1;
        } else if i > 0 && dp[i][j] == dp[i - 1][j] + 1 {
            ops.push(DiffOp::Delete(q[i - 1]));
            i -= 1;
        } else {
            ops.push(DiffOp::Insert(t[j - 1]));
            j -= 1;
        }
    }

    ops.reverse();
    ops
}

fn format_highlight(ops: &[DiffOp]) -> String {
    let mut out = String::new();
    for op in ops {
        match op {
            DiffOp::Match(c) => out.push(*c),
            DiffOp::Replace(u, t) => out.push_str(&format!("~~{}->{}~~", u, t)),
            DiffOp::Delete(u) => out.push_str(&format!("--{}--", u)),
            DiffOp::Insert(t) => out.push_str(&format!("++{}++", t)),
            DiffOp::Transpose(a, b) => out.push_str(&format!("<>{}{}<>", a, b)),
        }
    }
    out
}

fn common_prefix_len(a: &str, b: &str) -> usize {
    a.chars()
        .zip(b.chars())
        .take_while(|(ca, cb)| ca == cb)
        .count()
}

fn collapse_duplicates(s: &str) -> String {
    let mut result = String::new();
    let mut last_char = None;
    for c in s.chars() {
        if Some(c) != last_char {
            result.push(c);
            last_char = Some(c);
        }
    }
    result
}

fn main() {
    // --- Build everything ONCE at startup ---
    let mut dict_words: Vec<(String, String)> = Vec::new(); // (original, lowercase)
    let mut freq_map: HashMap<String, u64> = HashMap::new();
    let mut dict_set: HashSet<String> = HashSet::new();

    for line in DICT_DATA.lines() {
        if let Some((word, freq_str)) = line.trim().rsplit_once('\t') {
            let lower = word.to_lowercase();
            let freq: u64 = freq_str.trim().parse().unwrap_or(1);
            freq_map.insert(lower.clone(), freq);
            dict_set.insert(lower.clone());
            dict_words.push((word.to_string(), lower));
        }
    }

    // Bucket dictionary indices by word length
    let mut dict_by_len: HashMap<usize, Vec<usize>> = HashMap::new();
    for (idx, (_, lower)) in dict_words.iter().enumerate() {
        dict_by_len
            .entry(lower.chars().count())
            .or_default()
            .push(idx);
    }

    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        if let Ok(word) = line {
            let query = word.trim().to_lowercase();
            if query.is_empty() {
                continue;
            }

            if dict_set.contains(&query) {
                println!("*");
                continue;
            }

            let collapsed_query = collapse_duplicates(&query);
            let query_len = query.chars().count();

            let mut candidates: Vec<(i64, &str)> = Vec::new();

            let lo = query_len.saturating_sub(4);
            let hi = query_len + 4;

            for len in lo..=hi {
                let Some(indices) = dict_by_len.get(&len) else {
                    continue;
                };

                for &idx in indices {
                    let (orig, lower_w) = &dict_words[idx];

                    let dist = damerau_distance(&query, lower_w);
                    let collapsed_w = collapse_duplicates(lower_w);
                    let phonetic_match = collapsed_query == collapsed_w
                        || damerau_distance(&collapsed_query, &collapsed_w) <= 1;

                    if dist <= 3 || phonetic_match {
                        let prefix_len = common_prefix_len(&query, lower_w);
                        let freq = *freq_map.get(lower_w).unwrap_or(&1);
                        let freq_score = (freq as f64).log10();

                        let mut score = (dist as f64) * 50.0;
                        if phonetic_match {
                            score -= 80.0;
                        }
                        score -= (prefix_len as f64) * 12.0;
                        score -= freq_score * 10.0;

                        candidates.push((score as i64, orig.as_str()));
                    }
                }
            }

            candidates.sort_by_key(|(score, _)| *score);

            if candidates.is_empty() {
                println!("#");
            } else {
                let highlighted: Vec<String> = candidates
                    .into_iter()
                    .take(5)
                    .map(|(_, w)| {
                        let ops = diff_words(&query, &w.to_lowercase());
                        format_highlight(&ops)
                    })
                    .collect();

                println!("{}", highlighted.join(" "));
            }
        }
    }
}
