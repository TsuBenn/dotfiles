use std::{
    error::Error, io::{self, Read}, process, sync::mpsc::{Receiver, Sender}, thread
};

use crossterm::{
    cursor::{self},
    event::{Event, EventStream, KeyCode},
    terminal,
};
use ffmpeg_next::{codec::context, format::context::StreamIo};
use tokio_stream::StreamExt;

struct ChannelReader {
    rx: Receiver<Vec<u8>>,
    current_chunk: Option<std::io::Cursor<Vec<u8>>>,
}

impl ChannelReader {
    fn new(rx: Receiver<Vec<u8>>) -> Self {
        ChannelReader {
            rx,
            current_chunk: None,
        }
    }
}

impl Read for ChannelReader {
    fn read(&mut self, buf: &mut [u8]) -> io::Result<usize> {
        loop {
            if let Some(cursor) = &mut self.current_chunk {
                let n = cursor.read(buf)?;
                if n > 0 {
                    // println!("\rFFmpef: nom!");
                    return Ok(n);
                }

                self.current_chunk = None;
            }

            match self.rx.recv() {
                Ok(bytes) => {
                    self.current_chunk = Some(io::Cursor::new(bytes));
                }
                Err(_) => {
                    return Ok(0);
                }
            }
        }
    }
}

fn start_decoder_thread(decoder_rx: Receiver<Vec<u8>>) {
    thread::spawn(move || {
        if let Err(e) = ffmpeg_next::init() {
            println!("\rFailed to init FFmpeg: {:?}", e);
            process::exit(1);
        }

        println!("\rFFmpeg initialized successfully!\n");

        let reader = ChannelReader::new(decoder_rx);
        let io_stream = StreamIo::from_read(reader).unwrap();

        match ffmpeg_next::format::input_from_stream(io_stream, None, None) {
            Ok(mut ictx) => {
                println!("\rSuccessfully opened video container from stream!");
                let input = ictx.streams().best(ffmpeg_next::media::Type::Video).unwrap();

                let video_stream_index = input.index();

                let context = ffmpeg_next::codec::context::Context::from_parameters(input.parameters()).unwrap();

                let mut decoder = context.decoder().video().unwrap();

                println!("\rFound video stream at index {}!", video_stream_index);

                let mut frame = ffmpeg_next::util::frame::video::Video::empty();

                for (stream, packet) in ictx.packets() {
                    if stream.index() == video_stream_index {
                        decoder.send_packet(&packet).unwrap();
                        while decoder.receive_frame(&mut frame).is_ok() {
                            println!("\rDecoded a frame! Resolution: {}x{}, Format: {:?}", frame.width(), frame.height(), frame.format())
                        }
                    }
                }
            },
            Err(e) => {
                println!("\rFailed to open video container from stream: {}",e);
            }
        }

    });
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    terminal::enable_raw_mode()?;

    crossterm::execute!(std::io::stdout(), cursor::Hide,).unwrap();

    let (decoder_tx, decoder_rx) = std::sync::mpsc::channel::<Vec<u8>>();

    start_decoder_thread(decoder_rx);

    let (network_tx, mut network_rx) = tokio::sync::mpsc::channel::<Vec<u8>>(32);

    tokio::spawn(async move {
        let response = reqwest::get("https://samplelib.com/mp4/sample-5s-360p.mp4").await.unwrap();
        let mut stream = response.bytes_stream();

        while let Some(Ok(bytes)) = stream.next().await {
            if network_tx.send(bytes.to_vec()).await.is_err() {
                break;
            }
            // tokio::time::sleep(Duration::from_millis(500)).await;
        }
    });

    let mut event_stream = EventStream::new();

    println!("\rPlayer active! Press 'q' to quit!");

    let mut downloading = true;

    loop {
        tokio::select! {
            stream = network_rx.recv(), if downloading => {
                match stream {
                    Some(chunk) => {
                        if decoder_tx.send(chunk).is_err() {
                            break;
                        }
                    },
                    None => {
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

enum ControlAction {
    Quit,
    None,
}

fn handle_key_event(evt: Event) -> ControlAction {
    if let Event::Key(key) = evt {
        if key.code == KeyCode::Char('q') {
            println!("\n\rQuitting...");
            return ControlAction::Quit;
        }
    }
    return ControlAction::None;
}
