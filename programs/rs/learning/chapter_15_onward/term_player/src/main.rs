use std::{error::Error, thread};

use crossterm::{cursor::{self}, event::{Event, EventStream, KeyCode}, terminal};
use tokio_stream::StreamExt;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    terminal::enable_raw_mode()?;

    crossterm::execute!(
        std::io::stdout(),
        cursor::Hide,
    ).unwrap();

    let (decoder_tx, decoder_rx) = std::sync::mpsc::channel::<Vec<u8>>();

    thread::spawn(move || {

    });

    let (network_tx, mut network_rx) = tokio::sync::mpsc::channel::<Vec<u8>>(32);

    tokio::spawn(async move {
        let response = reqwest::get("https://file-examples.com/storage/fe285899456ad57fb947610/2017/04/file_example_MP4_1920_18MG.mp4").await.unwrap();
        let mut stream = response.bytes_stream();

        while let Some(Ok(bytes)) = stream.next().await {
            if network_tx.send(bytes.to_vec()).await.is_err() {
                break;
            }
        }
    });

    let mut event_stream = EventStream::new();

    println!("Player active! Press 'q' to quit!");

    let mut byte_count = 0;
    let mut downloading = true;

    loop {
        tokio::select! {
            stream = network_rx.recv(), if downloading => {
                match stream {
                    Some(chunk) => {
                        byte_count += chunk.len();
                        handle_video_chunk(chunk);
                    },
                    None => {
                        println!("\rFinished, total byte fetched: {}", byte_count);
                        downloading = false;
                    }
                }
            }
            Some(Ok(evt)) = event_stream.next() => {
                match handle_key_event(evt) {
                    ControlAction::Quit => break,
                    _ => {}
                }
            }
        }
    }

    terminal::disable_raw_mode()?;
    Ok(())
}

fn handle_video_chunk(chunk: Vec<u8>) {
    println!("\rReceived data chunk of {} bytes", chunk.len());
}

enum ControlAction {
    Quit,
    None
}

fn handle_key_event(evt: Event) -> ControlAction {
    if let Event::Key(key) = evt {
        if key.code == KeyCode::Char('q') {
            println!("\n\rQuitting...");
            return ControlAction::Quit;
        }
    }
    return ControlAction::None
}
