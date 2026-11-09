use std::{
    error::Error,
    fmt::Write,
    io::{self, Read},
    process,
    sync::mpsc::Receiver,
    thread,
    time::Instant,
};

use crossterm::{
    cursor::{self},
    event::{Event, EventStream, KeyCode},
    style, terminal,
};
use ffmpeg_next::{
    format::context::StreamIo,
    software::scaling::{self, Flags},
};
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
                // println!("\rSuccessfully opened video container from stream!");
                let input = ictx
                    .streams()
                    .best(ffmpeg_next::media::Type::Video)
                    .unwrap();

                let video_stream_index = input.index();

                let context =
                    ffmpeg_next::codec::context::Context::from_parameters(input.parameters())
                        .unwrap();

                let mut decoder = context.decoder().video().unwrap();

                println!("\rFound video stream at index {}!", video_stream_index);

                let mut frame = ffmpeg_next::util::frame::video::Video::empty();
                let mut rgb_frame = ffmpeg_next::util::frame::video::Video::empty();

                let padding = 1;

                let (mut ter_w, mut ter_h) = terminal::size().unwrap();
                ter_w -= padding * 4;
                ter_h -= padding * 2;
                let mut w = ter_w;
                let mut h = ter_h * 2;
                let video_ratio = (decoder.width() as f64) / (decoder.height() as f64);
                let ter_ratio = (w as f64) / (h as f64);

                if video_ratio > ter_ratio {
                    h = (w as f64 / video_ratio) as u16;
                } else {
                    w = (h as f64 * video_ratio) as u16;
                }

                let mut sws = scaling::context::Context::get(
                    decoder.format(),
                    decoder.width(),
                    decoder.height(),
                    ffmpeg_next::format::Pixel::RGB24,
                    w as u32,
                    h as u32,
                    Flags::FAST_BILINEAR,
                )
                .unwrap();

                crossterm::execute!(io::stdout(), terminal::Clear(terminal::ClearType::All))
                    .unwrap();

                for (stream, packet) in ictx.packets() {
                    if stream.index() == video_stream_index {
                        decoder.send_packet(&packet).unwrap();
                        while decoder.receive_frame(&mut frame).is_ok() {
                            sws.run(&frame, &mut rgb_frame).unwrap();
                            let rgb_data = rgb_frame.data(0);
                            let rgb_stride = rgb_frame.stride(0);
                            let width = rgb_frame.width() as usize;
                            let height = rgb_frame.height() as usize;

                            // Preallocate a big enough buffer for the whole frame once (outside the loop)
                            let mut frame_buffer = String::with_capacity(width * height * 32);

                            // Inside your frame loop:
                            frame_buffer.clear();

                            // Move cursor to top-left once per frame
                            frame_buffer.push_str("\x1b[H");

                            for y in (0..height).step_by(2) {
                                let top_row_idx = y * rgb_stride;
                                let bottom_row_idx = (y + 1) * rgb_stride;
                                for x in 0..width {
                                    let top_idx = top_row_idx + (x * 3);
                                    let bottom_idx = bottom_row_idx + (x * 3);

                                    let tr = rgb_data[top_idx];
                                    let tg = rgb_data[top_idx + 1];
                                    let tb = rgb_data[top_idx + 2];

                                    let br = rgb_data[bottom_idx];
                                    let bg = rgb_data[bottom_idx + 1];
                                    let bb = rgb_data[bottom_idx + 2];

                                    let _ = write!(
                                        &mut frame_buffer,
                                        "\x1b[38;2;{};{};{}m\x1b[48;2;{};{};{}m▀",
                                        tr, tg, tb, br, bg, bb
                                    );
                                }
                                frame_buffer.push_str("\r\n");
                            }

                            frame_buffer.push_str("\x1b[0m");

                            use std::io::Write;

                            io::stdout().write_all(frame_buffer.as_bytes()).unwrap();
                            io::stdout().flush().unwrap();
                        }
                    }
                }
            }
            Err(e) => {
                println!("\rFailed to open video container from stream: {}", e);
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
        let response = reqwest::get("https://samplelib.com/mp4/sample-10s-360p.mp4")
            .await
            .unwrap();
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

    crossterm::execute!(std::io::stdout(), cursor::Show,).unwrap();
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
