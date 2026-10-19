use std::{
    fs::File,
    io::{BufRead, BufReader, BufWriter, Read, Write},
    process,
    time::Instant,
};

use input_utils::get_num_with_default;

fn main() {
    let input_file = "input.ppm";
    let output_file = "output.ppm";

    let (width, height, mut pixel_buffer) = load_p6_image(input_file).unwrap_or_else(|e| {
        println!("Error Loading P6 Image: {e}");
        process::exit(1);
    });

    println!("Succesfully loaded P6 Image!");
    println!();

    let mut kernel_size;
    loop {
        kernel_size = get_num_with_default("Enter Kernel Size {}: ", 3);
        if kernel_size % 2 == 0 {
            println!("Kernel size needs to be an odd number!")
        } else {
            break;
        }
    }

    println!();
    println!("Applying Box Blur (Kernel size: {})...", kernel_size);
    println!();

    let mut start;
    let mut duration;
    let thread_counts = std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4);

    start = Instant::now();
    apply_box_blur_single_thread(width, height, &mut pixel_buffer, kernel_size).unwrap_or_else(
        |e| {
            println!("Error Applying Box Blur to P6 Image: {e}");
            process::exit(1);
        },
    );
    duration = start.elapsed();
    println!(
        "Finished applying Box Blur (Single-threaded)... (Time spent: {:.3} ms)",
        duration.as_nanos() as f64 / 1000000.0
    );
    println!();

    start = Instant::now();
    apply_box_blur_multi_thread(width, height, &mut pixel_buffer, kernel_size, thread_counts).unwrap_or_else(|e| {
        println!("Error Applying Box Blur to P6 Image: {e}");
        process::exit(1);
    });
    duration = start.elapsed();

    println!("Finished applying Box Blur (Multi-threaded)... (Time spent: {:.3} ms)", duration.as_nanos() as f64 / 1000000.0);
    println!();

    start = Instant::now();
    apply_box_blur_single_thread_sliding_window(width, height, &mut pixel_buffer, kernel_size).unwrap_or_else(|e| {
        println!("Error Applying Box Blur to P6 Image: {e}");
        process::exit(1);
    });
    duration = start.elapsed();

    println!("Finished applying Box Blur (Single-threaded, Sliding Window)... (Time spent: {:.3} ms)", duration.as_nanos() as f64 / 1000000.0);
    println!();

    start = Instant::now();
    apply_box_blur_multi_thread_sliding_window(width, height, &mut pixel_buffer, kernel_size, thread_counts).unwrap_or_else(|e| {
        println!("Error Applying Box Blur to P6 Image: {e}");
        process::exit(1);
    });
    duration = start.elapsed();

    println!("Finished applying Box Blur (Multi-threaded, Sliding Window)... (Time spent: {:.3} ms)", duration.as_nanos() as f64 / 1000000.0);
    println!();

    save_p6_image(output_file, width, height, pixel_buffer).unwrap_or_else(|e| {
        println!("Error Saving P6 Image: {e}");
        process::exit(1);
    });

    println!("Succesfully save P6 Image!");
}

fn apply_box_blur_multi_thread(
    width: usize,
    height: usize,
    pixel_buffer: &mut Vec<u8>,
    kernel_size: isize,
    thread_counts: usize
) -> Result<(), String> {
    if pixel_buffer.len() != width * height * 3 {
        return Err("Not enough pixel data!".to_owned());
    }

    let row_per_thread = f64::ceil(height as f64 / thread_counts as f64) as usize;
    let bytes_per_thread = row_per_thread * width * 3;

    let mut output_buffer = vec![0u8; width * height * 3];
    let kernel_offset = (kernel_size - 1) / 2;

    std::thread::scope(|s| {
        for (i, output_chunks) in output_buffer.chunks_mut(bytes_per_thread).enumerate() {
            let start_y = i * row_per_thread;
            let end = output_chunks.len() / 3;
            let source_pixels = &pixel_buffer;

            s.spawn(move || {
                for i in 0..end {
                    let mut sum_r: usize = 0;
                    let mut sum_g: usize = 0;
                    let mut sum_b: usize = 0;
                    let mut count = 0;
                    let x = (i) as isize % width as isize;
                    let y = (i) as isize / width as isize + start_y as isize;
                    for ky in (y - kernel_offset)..=(y + kernel_offset) {
                        for kx in (x - kernel_offset)..=(x + kernel_offset) {
                            if kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize {
                                continue;
                            }
                            let pixel_index = (kx + ky * width as isize) * 3;
                            sum_r += source_pixels[pixel_index as usize] as usize;
                            sum_g += source_pixels[pixel_index as usize + 1] as usize;
                            sum_b += source_pixels[pixel_index as usize + 2] as usize;
                            count += 1;
                        }
                    }
                    output_chunks[i * 3] = (sum_r / count).clamp(0, 255) as u8;
                    output_chunks[(i * 3) + 1] = (sum_g / count).clamp(0, 255) as u8;
                    output_chunks[(i * 3) + 2] = (sum_b / count).clamp(0, 255) as u8;
                }
            });
        }
    });

    pixel_buffer.copy_from_slice(&output_buffer);
    Ok(())
}

fn apply_box_blur_multi_thread_sliding_window(
    width: usize,
    height: usize,
    pixel_buffer: &mut Vec<u8>,
    kernel_size: isize,
    thread_counts: usize
) -> Result<(), String> {
    if pixel_buffer.len() != width * height * 3 {
        return Err("Not enough pixel data!".to_owned());
    }

    let row_per_thread = f64::ceil(height as f64 / thread_counts as f64) as usize;
    let bytes_per_thread = row_per_thread * width * 3;

    let mut output_buffer = vec![0u8; width * height * 3];
    let kernel_offset = (kernel_size - 1) / 2;

    std::thread::scope(|s| {
        for (i, output_chunks) in output_buffer.chunks_mut(bytes_per_thread).enumerate() {
            let start_y = i * row_per_thread;
            let end = output_chunks.len() / 3;
            let source_pixels = &pixel_buffer;

            s.spawn(move || {
                let mut sum_r: usize = 0;
                let mut sum_g: usize = 0;
                let mut sum_b: usize = 0;
                let mut count = 0;
                for mut i in 0..end {
                    let y = (i) as isize / width as isize + start_y as isize;
                    if y % 2 != 0 {
                        i = (i / width) * width + (width - 1) - (i % width)
                    }
                    let x = (i) as isize % width as isize;
                    if count == 0 {
                        for ky in (y - kernel_offset)..=(y + kernel_offset) {
                            for kx in (x - kernel_offset)..=(x + kernel_offset) {
                                if kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize
                                {
                                    continue;
                                }
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r += source_pixels[pixel_index as usize] as usize;
                                sum_g += source_pixels[pixel_index as usize + 1] as usize;
                                sum_b += source_pixels[pixel_index as usize + 2] as usize;
                                count += 1;
                            }
                        }
                    } else if x > 0 && y % 2 == 0 {
                        for ky in (y - kernel_offset)..=(y + kernel_offset) {
                            let mut kx = x + kernel_offset;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r += source_pixels[pixel_index as usize] as usize;
                                sum_g += source_pixels[pixel_index as usize + 1] as usize;
                                sum_b += source_pixels[pixel_index as usize + 2] as usize;
                                count += 1;
                            }
                            kx = x - kernel_offset - 1;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r -= source_pixels[pixel_index as usize] as usize;
                                sum_g -= source_pixels[pixel_index as usize + 1] as usize;
                                sum_b -= source_pixels[pixel_index as usize + 2] as usize;
                                count -= 1;
                            }
                        }
                    } else if x < (width - 1) as isize && y % 2 != 0 {
                        for ky in (y - kernel_offset)..=(y + kernel_offset) {
                            let mut kx = x - kernel_offset;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r += source_pixels[pixel_index as usize] as usize;
                                sum_g += source_pixels[pixel_index as usize + 1] as usize;
                                sum_b += source_pixels[pixel_index as usize + 2] as usize;
                                count += 1;
                            }
                            kx = x + kernel_offset + 1;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r -= source_pixels[pixel_index as usize] as usize;
                                sum_g -= source_pixels[pixel_index as usize + 1] as usize;
                                sum_b -= source_pixels[pixel_index as usize + 2] as usize;
                                count -= 1;
                            }
                        }
                    } else {
                        for kx in (x - kernel_offset)..=(x + kernel_offset) {
                            let mut ky = y - kernel_offset - 1;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r -= source_pixels[pixel_index as usize] as usize;
                                sum_g -= source_pixels[pixel_index as usize + 1] as usize;
                                sum_b -= source_pixels[pixel_index as usize + 2] as usize;
                                count -= 1;
                            }
                            ky = y + kernel_offset;
                            if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize)
                            {
                                let pixel_index = (kx + ky * width as isize) * 3;
                                sum_r += source_pixels[pixel_index as usize] as usize;
                                sum_g += source_pixels[pixel_index as usize + 1] as usize;
                                sum_b += source_pixels[pixel_index as usize + 2] as usize;
                                count += 1;
                            }
                        }
                    }
                    output_chunks[i * 3] = (sum_r / count).clamp(0, 255) as u8;
                    output_chunks[(i * 3) + 1] = (sum_g / count).clamp(0, 255) as u8;
                    output_chunks[(i * 3) + 2] = (sum_b / count).clamp(0, 255) as u8;
                }
            });
        }
    });

    pixel_buffer.copy_from_slice(&output_buffer);
    Ok(())
}

fn apply_box_blur_single_thread(
    width: usize,
    height: usize,
    pixel_buffer: &mut Vec<u8>,
    kernel_size: isize,
) -> Result<(), String> {
    if pixel_buffer.len() != width * height * 3 {
        return Err("Not enough pixel data!".to_owned());
    }
    let mut output_buffer = vec![0u8; width * height * 3];
    let kernel_offset = (kernel_size - 1) / 2;

    for (i, _) in pixel_buffer.chunks(3).enumerate() {
        let mut sum_r: usize = 0;
        let mut sum_g: usize = 0;
        let mut sum_b: usize = 0;
        let mut count: usize = 0;
        let y = i as isize / width as isize;
        let x = i as isize % width as isize;
        for ky in (y - kernel_offset)..=(y + kernel_offset) {
            for kx in (x - kernel_offset)..=(x + kernel_offset) {
                if kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize {
                    continue;
                }
                let pixel_index = (kx + ky * width as isize) * 3;
                sum_r += pixel_buffer[pixel_index as usize] as usize;
                sum_g += pixel_buffer[pixel_index as usize + 1] as usize;
                sum_b += pixel_buffer[pixel_index as usize + 2] as usize;
                count += 1;
            }
        }
        output_buffer[i * 3] = (sum_r / count).clamp(0, 255) as u8;
        output_buffer[(i * 3) + 1] = (sum_g / count).clamp(0, 255) as u8;
        output_buffer[(i * 3) + 2] = (sum_b / count).clamp(0, 255) as u8;
    }

    pixel_buffer.copy_from_slice(&output_buffer);
    Ok(())
}

fn apply_box_blur_single_thread_sliding_window(
    width: usize,
    height: usize,
    pixel_buffer: &mut Vec<u8>,
    kernel_size: isize,
) -> Result<(), String> {
    if pixel_buffer.len() != width * height * 3 {
        return Err("Not enough pixel data!".to_owned());
    }
    let mut output_buffer = vec![0u8; width * height * 3];
    let kernel_offset = (kernel_size - 1) / 2;

    let mut sum_r: usize = 0;
    let mut sum_g: usize = 0;
    let mut sum_b: usize = 0;
    let mut count: usize = 0;
    for (mut i, _) in pixel_buffer.chunks(3).enumerate() {
        let y = i as isize / width as isize;
        if y % 2 != 0 {
            i = (i / width) * width + (width - 1) - (i % width)
        }
        let x = i as isize % width as isize;
        if count == 0 {
            for ky in (y - kernel_offset)..=(y + kernel_offset) {
                for kx in (x - kernel_offset)..=(x + kernel_offset) {
                    if kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize {
                        continue;
                    }
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r += pixel_buffer[pixel_index as usize] as usize;
                    sum_g += pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b += pixel_buffer[pixel_index as usize + 2] as usize;
                    count += 1;
                }
            }
        } else if x > 0 && y % 2 == 0 {
            for ky in (y - kernel_offset)..=(y + kernel_offset) {
                let mut kx = x + kernel_offset;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r += pixel_buffer[pixel_index as usize] as usize;
                    sum_g += pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b += pixel_buffer[pixel_index as usize + 2] as usize;
                    count += 1;
                }
                kx = x - kernel_offset - 1;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r -= pixel_buffer[pixel_index as usize] as usize;
                    sum_g -= pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b -= pixel_buffer[pixel_index as usize + 2] as usize;
                    count -= 1;
                }
            }
        } else if x < (width - 1) as isize && y % 2 != 0 {
            for ky in (y - kernel_offset)..=(y + kernel_offset) {
                let mut kx = x - kernel_offset;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r += pixel_buffer[pixel_index as usize] as usize;
                    sum_g += pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b += pixel_buffer[pixel_index as usize + 2] as usize;
                    count += 1;
                }
                kx = x + kernel_offset + 1;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r -= pixel_buffer[pixel_index as usize] as usize;
                    sum_g -= pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b -= pixel_buffer[pixel_index as usize + 2] as usize;
                    count -= 1;
                }
            }
        } else {
            for kx in (x - kernel_offset)..=(x + kernel_offset) {
                let mut ky = y - kernel_offset - 1;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r -= pixel_buffer[pixel_index as usize] as usize;
                    sum_g -= pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b -= pixel_buffer[pixel_index as usize + 2] as usize;
                    count -= 1;
                }
                ky = y + kernel_offset;
                if !(kx < 0 || kx >= width as isize || ky < 0 || ky >= height as isize) {
                    let pixel_index = (kx + ky * width as isize) * 3;
                    sum_r += pixel_buffer[pixel_index as usize] as usize;
                    sum_g += pixel_buffer[pixel_index as usize + 1] as usize;
                    sum_b += pixel_buffer[pixel_index as usize + 2] as usize;
                    count += 1;
                }
            }
        }

        // println!("x: {x}, y: {y}, count: {count}");
        // if count > 9 {
        //     sleep(Duration::from_millis(500));
        // }

        output_buffer[i * 3] = (sum_r / count).clamp(0, 255) as u8;
        output_buffer[(i * 3) + 1] = (sum_g / count).clamp(0, 255) as u8;
        output_buffer[(i * 3) + 2] = (sum_b / count).clamp(0, 255) as u8;
    }

    pixel_buffer.copy_from_slice(&output_buffer);
    Ok(())
}

fn save_p6_image(
    path: &str,
    width: usize,
    height: usize,
    pixel_buffer: Vec<u8>,
) -> Result<(), String> {
    let file = File::create(path).map_err(|e| e.to_string())?;

    let mut writer = BufWriter::new(file);

    writer
        .write_fmt(format_args!("P6\n{} {}\n255\n", width, height))
        .map_err(|e| e.to_string())?;
    writer.write_all(&pixel_buffer).map_err(|e| e.to_string())?;

    Ok(())
}

fn load_p6_image(path: &str) -> Result<(usize, usize, Vec<u8>), String> {
    let file = File::open(path).map_err(|e| e.to_string())?;
    let mut reader = BufReader::new(file);

    let mut line = String::new();

    reader.read_line(&mut line).map_err(|e| e.to_string())?;

    if line.trim() != "P6" {
        return Err("Invalid P6 Image file".to_owned());
    }

    line.clear();

    reader.read_line(&mut line).map_err(|e| e.to_string())?;

    let mut dimensions = line.split_whitespace();
    let Some(width) = dimensions.next() else {
        return Err("No width data found!".to_owned());
    };
    let Some(height) = dimensions.next() else {
        return Err("No height data found!".to_owned());
    };

    let width: usize = width.parse::<usize>().map_err(|e| e.to_string())?;
    let height: usize = height.parse::<usize>().map_err(|e| e.to_string())?;

    // Assuming the pixel max value is 255
    reader.read_line(&mut line).map_err(|e| e.to_string())?;

    let mut pixel_buffer = vec![0u8; width * height * 3];

    reader
        .read_exact(&mut pixel_buffer)
        .map_err(|e| e.to_string())?;

    Ok((width, height, pixel_buffer))
}
