fn main() {
    
    let list = vec![21,53,27,47,27,16,82];

    let largest = max(&list);

    println!("The largest number in vector {:?} is {}", list, largest);

}

fn max(list: &[i32]) -> i32 {
    let mut largest = list[0];
    for &num in list {
        if num > largest {
            largest = num;
        }
    }
    largest
}
