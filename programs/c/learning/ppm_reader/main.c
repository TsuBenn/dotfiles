#include "input.h"
#include "tsring.h"
#include "vec.h"
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

#define loop(x) for(size_t i = 0; i < x; i++)

#define ARRAY_LEN(arr) (sizeof(arr) / sizeof((arr)[0]))

typedef struct Image {
  vec_t* pixels;
  int height;
  int width;
  int max;
} image_t;

typedef struct Pixel {
  size_t r;
  size_t g;
  size_t b;
} pixel_t;

int parse_file_old(string_t* content, image_t *image);
int parse_file(string_t* content, image_t *image);
void apply_grayscale(image_t *image);
void apply_invert(image_t *image);
void apply_box_blur(image_t *image);
int save_ppm(const char* file_path, image_t* img);

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

  string_t *content = string_read_from_file(argv[1], NULL);
  if (!content) {
    fprintf(stderr, "ppm_reader: Failed to open file %s", argv[1]);
    return 1;
  }

  image_t image;

  parse_file_old(content, &image);

  main_menu:
  printf("====================================================\n");
  printf(" PPM READER (by TsuBenn)                            \n");
  printf("====================================================\n");

  int choice = 0;
  char *main_menu[] = {
      "Grayscale Filter",
      "Invert Colors",
      "HSV Adjustment",
      "Box Blur",
      "Save to Output",
      "Quit",
  };
  int status = 0;
  for (;;) {
    status = input_get_menu_choice(&choice, "====================================================\n Choice {}: ", main_menu, ARRAY_LEN(main_menu), NULL);
    if (status == 0) {
      fprintf(stderr, "\nThis field shall not be empty!\n\n");
      input_pause("Press Enter to continue...");
      fprintf(stderr, "\n");
    } else if (status == -1) {
      fprintf(stderr, "\nInvalid selection!!\n\n");
      input_pause("Press Enter to continue...");
      fprintf(stderr, "\n");
    } else {
      break;
    }
    goto main_menu;
  }

  switch (choice) {
    case 0:
      printf("\nProcessing...");
      apply_grayscale(&image);
      printf("\rApplied Grayscale filter Successfully!    \n\n");
      goto main_menu;
      break;
    case 1:
      printf("\nProcessing...");
      apply_invert(&image);
      printf("\rApplied Invert Colors filter Successfully!    \n\n");
      goto main_menu;
      break;
    case 2:
      goto main_menu;
      break;
    case 3:
      goto main_menu;
      break;
    case 4:
      printf("\nSaving to %s...\n", argv[2]);
      if (!save_ppm(argv[2], &image)) {
        fprintf(stderr, "\nFailed saving to %s\n\n", argv[2]);
      } else {
        printf("\nSuccessfully saved to %s\n\n", argv[2]);
      }
      goto main_menu;
      break;
    default:
      printf("\nQuitting...\n");
      goto clean_up;
  }

  err = 0;

  clean_up:
  vec_free(image.pixels);
  string_free(content);
  return err;
}

int parse_file(string_t* content, image_t* image) {
  chars_t* chars = chars_from(content->buf);

}

int parse_file_old(string_t* content, image_t* image) {
  string_t *buffer = string_new(256);
  size_t offset = 0;

  int ok = 0;

  if (content->len == 0) {
    fprintf(stderr, "ppm_reader: Empty file!\n");
    goto clean_up;
  }

  // Check header

  // Check Image Type
  next(content, buffer, &offset);
  if (!string_eq_str(buffer, "P3")) {
    fprintf(stderr, "ppm_reader: Invalid PPM file (%s)!\n", buffer->buf);
    goto clean_up;
  }

  // Check Check Width
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Width!\n");
    goto clean_up;
  }

  if (buffer->buf[0] == '#') string_read_delimiter(content, buffer, &offset, "\n", 1);

  if (!string_parse_int(buffer, &image->width)) {
    fprintf(stderr, "ppm_reader: Invalid Image Width!\n");
    goto clean_up;
  }

  // Check Check Height
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Height!\n");
    goto clean_up;
  }

  if (!string_parse_int(buffer, &image->height)) {
    fprintf(stderr, "ppm_reader: Invalid Image Height!\n");
    goto clean_up;
  }

  // Check Color Max Value
  if (!next(content, buffer, &offset)) {
    fprintf(stderr, "ppm_reader: Can't get Image Color Max Value!\n");
    goto clean_up;
  }

  if (!string_parse_int(buffer, &image->max)) {
    fprintf(stderr, "ppm_reader: Invalid Image Color Max Value!\n");
    goto clean_up;
  }

  image->pixels = vec_new_t(pixel_t, image->width*image->height);

  pixel_t tmp_pixel;
  // 0 -> r
  // 1 -> g
  // 2 -> b
  int rgb_idx = 0;

  size_t total_pixels = image->width*image->height;

  printf("Loading %zu Pixels...", total_pixels);
  fflush(stdout);
  while (next(content, buffer, &offset)) {
    int value = 0;
    if (!string_parse_int(buffer, &value)) {
      fprintf(stderr, "ppm_reader: Corrupted Pixel Data!\n");
      goto clean_up;
    }

    if (value < 0) value = 0;
    if (value > image->max) value = image->max;

    switch (rgb_idx) {
      case 0:
        tmp_pixel.r = value;
        break;
      case 1:
        tmp_pixel.g = value;
        break;
      case 2:
        tmp_pixel.b = value;
        vec_push(image->pixels, &tmp_pixel);
        break;
    }

    rgb_idx = (rgb_idx + 1) % 3; // loop back to 0 every 1 pixel
  }
  printf("\r%zu pixels fully loaded!           \n", total_pixels);

  if (!(image->pixels->len == total_pixels)) {
    fprintf(stderr, "ppm_reader: Pixel count doesn't match with resolution!\n");
  }

  ok = 1;

  clean_up:
  string_free(buffer);
  return ok;
}

void apply_grayscale(image_t *image) {
  for (size_t i = 0; i < image->pixels->len; i++) {
    pixel_t* pixel;
    if ((pixel = vec_get_t(image->pixels, i, pixel_t))) {
      size_t avg_val = (pixel->r+pixel->b+pixel->b)/3;
      pixel->r = pixel->g = pixel->b = avg_val;
    }
  }
}

void apply_invert(image_t *image) {
  for (size_t i = 0; i < image->pixels->len; i++) {
    pixel_t* pixel;
    if ((pixel = vec_get_t(image->pixels, i, pixel_t))) {
      pixel->r = image->max - pixel->r;
      pixel->g = image->max - pixel->g;
      pixel->b = image->max - pixel->b;
    }
  }
}

int save_ppm(const char* file_path, image_t* image) {

  FILE* file = fopen(file_path, "w");
  if (!file) {
    perror("Failed to open file for writing: ");
    return 0;
  }

  int ok = 0;

  fprintf(file, "P3\n%d %d\n%d\n", image->width, image->height, image->max);

  for (size_t r = 0; r < (size_t)image->height; r++) {
    for (size_t c = 0; c < (size_t)image->width; c++) {
      pixel_t* pixel = vec_get_t(image->pixels, r * image->width + c, pixel_t);
      if (!pixel) goto clean_up;
      fprintf(file, "%zu %zu %zu", pixel->r, pixel->g, pixel->b);
      if (c == (size_t)image->width - 1) {
        fprintf(file, "\n");
      } else {
        fprintf(file, " ");
      }
    }
  }

  ok = 1;

  clean_up:
  fclose(file);
  return ok;
}
