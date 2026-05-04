enum Weather {
    Sunny,
    Rainy(u8),
    Snowy
}

fn main() {

    let weather: Option<Weather> = Some(Weather::Rainy(6));

    let x = 5;

    match weather {
        Some(Weather::Rainy(i)) => println!("Heavy rain!"),
        Some(Weather::Rainy(i)) => println!("Light rain!"),
        _ => ()
    }

}
