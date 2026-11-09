use std::time::Instant;

fn main() {
    println!("debug assertions: {}", cfg!(debug_assertions)); // true = debug build

    let bytes = std::fs::read("navia.png").unwrap();

    let t = Instant::now();
    let mut decoder = png::Decoder::new(std::io::Cursor::new(&bytes));
    decoder.set_transformations(png::Transformations::EXPAND | png::Transformations::STRIP_16);
    let mut reader = decoder.read_info().unwrap();
    let mut buf = vec![0; reader.output_buffer_size().unwrap()];
    let info = reader.next_frame(&mut buf).unwrap();
    println!("decode only: {:?}", t.elapsed());
    println!("{:?} {:?} interlaced: {}", info.color_type, info.bit_depth, reader.info().interlaced);
}
