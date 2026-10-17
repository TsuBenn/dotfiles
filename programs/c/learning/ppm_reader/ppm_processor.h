#ifndef PPM_PROCESSOR_H
#define PPM_PROCESSOR_H

#include "tsring.h"
#include "vec.h"
#include <ctype.h>
#include <stddef.h>

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

typedef struct HSV {
  float h;
  float s;
  float v;
} hsv_t;

int parse_file(string_t* content, image_t *image);

int save_ppm(const char* file_path, image_t* img);

void apply_grayscale(image_t *image);

void apply_invert(image_t *image);

hsv_t rgb_to_hsv(pixel_t* pixel, int max);

pixel_t hsv_to_rgb(hsv_t* hsv, int max);

void hsv_add_hsv(hsv_t* hsv, hsv_t* other_hsv);

void apply_hsv_adjustment(image_t *image, hsv_t* hsv_offset);

void apply_box_blur(image_t *image, size_t kernel);

pixel_t* get_pixel(image_t *image, size_t x, size_t y);

size_t get_pixel_x(image_t *image, size_t index);

size_t get_pixel_y(image_t *image, size_t index);

#endif
