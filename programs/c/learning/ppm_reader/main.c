#include "input.h"
#include "tsring.h"
#include "vec.h"
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

#define loop(x) for(size_t i = 0; i < x; i++)

typedef struct Image {
  vec_t* pixels;
  int height;
  int width;
  int max;
} image_t;

typedef struct Pixel {
  int r;
  int g;
  int b;
} pixel_t;

int next(string_t* content, string_t* buffer, size_t* offset) {
  if (content->buf[*offset] == '#') {
    while (content->buf[*offset] != '\n' && content->buf[*offset] != '\0') {
      (*offset)++;
    }
    (*offset)++;
  }
  return string_read_delimiter(content, buffer, offset, " \r\t\n", 1) != NULL;
}

int main(int argc, char *argv[]) {

  string_t* input = string_new(256);
  input_get_string(input, "Enter your name {}: ", "nobody");

  printf("%s!\n", input->buf);

  string_free(input);
  return 0;

  if (argc < 3) {
    fprintf(stderr, "Usage: %s <input> <output>\n", argv[0]);
    return 0;
  }

  FILE* file = fopen(argv[1], "r");
  if (!file) {
    perror("ppm_reader (file: open)");
    return 1;
  }

  int err = 1;

  image_t image;

  string_t *content = string_read_from_file(argv[1], NULL);
  if (!content) {
    fprintf(stderr, "ppm_reader: Failed to open file %s", argv[1]);
    return 1;
  }

  string_t *buffer = string_new(256);
  size_t offset = 0;

  if (content->len == 0) {
    fprintf(stderr, "ppm_reader: Empty file!\n");
    goto cleanup;
  }

  // Check header

  // Check Image Type
  next(content, buffer, &offset);
  if (!string_eq_str(buffer, "P3")) {
    fprintf(stderr, "ppm_reader: Invalid PPM file (%s)!\n", buffer->buf);
    goto cleanup;
  }

  // Check Check Width
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Width!\n");
    goto cleanup;
  }

  if (buffer->buf[0] == '#') string_read_delimiter(content, buffer, &offset, "\n", 1);

  if (!string_parse_int(buffer, &image.width)) {
    fprintf(stderr, "ppm_reader: Invalid Image Width!\n");
    goto cleanup;
  }

  // Check Check Height
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Height!\n");
    goto cleanup;
  }

  if (!string_parse_int(buffer, &image.height)) {
    fprintf(stderr, "ppm_reader: Invalid Image Height!\n");
    goto cleanup;
  }

  // Check Color Max Value
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Color Max Value!\n");
    goto cleanup;
  }

  if (!string_parse_int(buffer, &image.max)) {
    fprintf(stderr, "ppm_reader: Invalid Image Color Max Value!\n");
    goto cleanup;
  }

  image.pixels = vec_new_t(pixel_t, 256);

  pixel_t tmp_pixel;
  // 0 -> r
  // 1 -> g
  // 2 -> b
  int rgb_idx = 0;

  size_t total_pixels = image.width*image.height;

  printf("Loading %zu Pixels...", total_pixels);
  fflush(stdout);

  while (next(content, buffer, &offset)) {
    int value = 0;
    if (!string_parse_int(buffer, &value)) {
      fprintf(stderr, "ppm_reader: Corrupted Pixel Data!\n");
      goto cleanup;
    }

    if (value < 0) value = 0;
    if (value > image.max) value = image.max;

    switch (rgb_idx) {
      case 0:
        tmp_pixel.r = value;
        break;
      case 1:
        tmp_pixel.g = value;
        break;
      case 2:
        tmp_pixel.b = value;
        vec_push(image.pixels, &tmp_pixel);
        break;
    }

    rgb_idx = (rgb_idx + 1) % 3; // loop back to 0 every 1 pixel
  }

  printf("\r%zu pixels fully loaded!           \n", total_pixels);

  if (!(image.pixels->len == total_pixels)) {
    fprintf(stderr, "ppm_reader: Pixel count doesn't match with resolution!\n");
  }

  err = 0;

  cleanup:
  vec_free(image.pixels);
  string_free(content);
  string_free(buffer);
  return err;
}
