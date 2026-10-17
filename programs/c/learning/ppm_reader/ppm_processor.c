#include "tsring.h"
#include "vec.h"
#include <ctype.h>
#include <math.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ppm_processor.h"

int next_valid(chars_t *chars) {
  if (!chars_skip_whitespaces(chars)) {
    return 0;
  }
  if (chars(chars) == '#') {
    if (!chars_next_until(chars, '\n')) {
      return 0;
    }
  }
  return 1;
}

int next_int(chars_t *chars, int *num) {
  if (!next_valid(chars)) {
    return 0;
  }
  for_chars(c, chars) {
    if (!isdigit(*c)) {
      if (isspace(*c)) {
        break;
      }
      return 0;
    }
    *num = *num * 10 + (*c - '0');
  }
  return 1;
}

int parse_file(string_t *content, image_t *image) {
  if (content->len == 0) {
    fprintf(stderr, "ppm_reader: Empty file!\n");
    return 0;
  }
  chars_t *chars = chars_from(content->buf);
  int ok = 0;

  if (!next_valid(chars)) {
    fprintf(stderr, "ppm_reader: Empty file!\n");
  }
  if (!chars_match(chars, "P3")) {
    fprintf(stderr, "ppm_reader: Invalid PPM P3 file!\n");
    goto clean_up;
  }

  if (!next_int(chars, &image->width)) {
    fprintf(stderr, "ppm_reader: Failed to read Image width!\n");
    goto clean_up;
  }

  if (!next_int(chars, &image->height)) {
    fprintf(stderr, "ppm_reader: Failed to read Image height!\n");
    goto clean_up;
  }

  if (!next_int(chars, &image->max)) {
    fprintf(stderr, "ppm_reader: Failed to read Image max value!\n");
    goto clean_up;
  }

  size_t total_pixels = image->width * image->height;
  vec_reserve(image->pixels, total_pixels);

  // 0 -> r
  // 1 -> g
  // 2 -> b
  int rgb_idx = 0;
  pixel_t tmp_pixel;
  int tmp = 0;

  printf("Loading %zu Pixels...", total_pixels);
  fflush(stdout);

  while (next_int(chars, &tmp)) {
    switch (rgb_idx) {
    case 0:
      tmp_pixel.r = (size_t)tmp;
      tmp = 0;
      rgb_idx = 1;
      break;
    case 1:
      tmp_pixel.g = (size_t)tmp;
      tmp = 0;
      rgb_idx = 2;
      break;
    case 2:
      tmp_pixel.b = (size_t)tmp;
      tmp = 0;
      rgb_idx = 0;
      vec_push(image->pixels, &tmp_pixel);
      break;
    }
  }

  if (image->pixels->len < total_pixels) {
    fprintf(stderr, "ppm_reader: Corrupted pixel data!\n");
    goto clean_up;
  }

  printf("\r%zu pixels successfully loaded!\n", total_pixels);

  ok = 1;

clean_up:
  chars_free(chars);
  return ok;
}

int save_ppm(const char *file_path, image_t *image) {

  FILE *file = fopen(file_path, "w");
  if (!file) {
    perror("Failed to open file for writing: ");
    return 0;
  }

  int ok = 0;

  fprintf(file, "P3\n%d %d\n%d\n", image->width, image->height, image->max);

  for (size_t r = 0; r < (size_t)image->height; r++) {
    for (size_t c = 0; c < (size_t)image->width; c++) {
      pixel_t *pixel = vec_get_t(image->pixels, r * image->width + c, pixel_t);
      if (!pixel)
        goto clean_up;
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

void apply_grayscale(image_t *image) {
  for (size_t i = 0; i < image->pixels->len; i++) {
    pixel_t *pixel;
    if ((pixel = vec_get_t(image->pixels, i, pixel_t))) {
      size_t avg_val = (pixel->r + pixel->g + pixel->b) / 3;
      pixel->r = pixel->g = pixel->b = avg_val;
    }
  }
}

void apply_invert(image_t *image) {
  for (size_t i = 0; i < image->pixels->len; i++) {
    pixel_t *pixel;
    if ((pixel = vec_get_t(image->pixels, i, pixel_t))) {
      pixel->r = image->max - pixel->r;
      pixel->g = image->max - pixel->g;
      pixel->b = image->max - pixel->b;
    }
  }
}

hsv_t rgb_to_hsv(pixel_t *pixel, int max) {
  float nr = (pixel->r / (float)max);
  float ng = (pixel->g / (float)max);
  float nb = (pixel->b / (float)max);

  float nmax = fmax(nr, fmax(ng, nb));
  float nmin = fmin(nr, fmin(ng, nb));

  float delta = nmax - nmin;

  hsv_t hsv = {nmax,nmax,nmax};

  hsv.s = nmax != 0 ? delta / (nmax) : 0;

  if (delta == 0.0f) {
    hsv.h = 0.0f;
  } else {
    if (nmax == nr) {
      hsv.h = fmodf((ng-nb)/delta,6.0f);
    } else if (nmax == ng) {
      hsv.h = (nb-nr)/delta + 2.0f;
    } else if (nmax == nb) {
      hsv.h = (nr-ng)/delta + 4.0f;
    }
    hsv.h *= 60.0f;
  }

  if (hsv.h < 0.0f) {
    hsv.h += 360.0;
  } else if (hsv.h > 360.0f) {
    hsv.h -= 360.0;
  }

  return hsv;
}

pixel_t hsv_to_rgb(hsv_t *hsv, int max) {
  pixel_t pixel;

  if (hsv->s <= 0.0f) {
    pixel.r = pixel.g = pixel.b = hsv->v * max;
    return pixel;
  }

  float c = hsv->v * hsv->s;
  float h_prime = fmodf(hsv->h / 60.0f, 6.0f);
  float x = (1.0f - fabsf(fmodf(h_prime, 2.0f)-1.0f)) * c;
  float m = hsv->v - c;

  float r_prime = 0.0f, g_prime = 0.0f, b_prime = 0.0f;

  // Pick the mix based on which 60-degree sector hue falls into
  if (h_prime >= 0.0f && h_prime < 1.0f) {
    r_prime = c;
    g_prime = x;
    b_prime = 0.0f;
  } else if (h_prime < 2.0f) {
    r_prime = x;
    g_prime = c;
    b_prime = 0.0f;
  } else if (h_prime < 3.0f) {
    r_prime = 0.0f;
    g_prime = c;
    b_prime = x;
  } else if (h_prime < 4.0f) {
    r_prime = 0.0f;
    g_prime = x;
    b_prime = c;
  } else if (h_prime < 5.0f) {
    r_prime = x;
    g_prime = 0.0f;
    b_prime = c;
  } else {
    r_prime = c;
    g_prime = 0.0f;
    b_prime = x;
  }

  // Add back the baseline brightness and scale to final output
  pixel.r = fmax(fmin((r_prime + m)*max, max), 0);
  pixel.g = fmax(fmin((g_prime + m)*max, max), 0);
  pixel.b = fmax(fmin((b_prime + m)*max, max), 0);

  return pixel;
}

void hsv_add_hsv(hsv_t *hsv, hsv_t *other_hsv) {
  hsv->h += other_hsv->h;
  if (hsv->h > 360.0) {
    hsv->h -= 360;
  } else if (hsv->h < 0) {
    hsv->h += 360;
  }
  hsv->s = hsv->s * (1 + other_hsv->s);
  if (hsv->s > 1.0) {
    hsv->s = 1.0;
  } else if (hsv->s < 0) {
    hsv->s = 0.0;
  }
  hsv->v = hsv->v * (1 + other_hsv->v);
  if (hsv->v > 1.0) {
    hsv->v = 1.0;
  } else if (hsv->v < 0) {
    hsv->v = 0.0;
  }
}

void apply_hsv_adjustment(image_t *image, hsv_t *hsv_offset) {
  for (size_t i = 0; i < image->pixels->len; i++) {
    pixel_t *pixel;
    if ((pixel = vec_get_t(image->pixels, i, pixel_t))) {
      hsv_t hsv = rgb_to_hsv(pixel, image->max);
      hsv_add_hsv(&hsv, hsv_offset);
      *pixel = hsv_to_rgb(&hsv, image->max);
    }
  }
}



pixel_t* get_pixel(image_t *image, size_t x, size_t y) {
  if (x < 0) x = 0; else if (x >= (size_t)image->width) x = image->width - 1;
  if (y < 0) y = 0; else if (y >= (size_t)image->height) y = image->height - 1;
  return vec_get_t(image->pixels, y * (size_t)image->width + x, pixel_t);
}

size_t get_pixel_x(image_t *image, size_t index) {
  if (index < 0) index = 0; else if (index >= (size_t)image->pixels->len) index = image->pixels->len-1;
  return index % (size_t)image->width;
}

size_t get_pixel_y(image_t *image, size_t index) {
  if (index < 0) index = 0; else if (index >= (size_t)image->pixels->len) index = image->pixels->len-1;
  return index / (size_t)image->width;
}

static void clamp_pixel(pixel_t* pixel, size_t max) {
  pixel->r = fmax(fmin(pixel->r, max), 0);
  pixel->g = fmax(fmin(pixel->g, max), 0);
  pixel->b = fmax(fmin(pixel->b, max), 0);
}

void apply_box_blur(image_t *image, size_t kernel) {
  vec_t* tmp_pixels = vec_new_t(pixel_t, image->width*image->height);
  for (size_t i = 0; i < image->pixels->len; i++) {
    size_t ko = (kernel-1)/2;
    size_t x = get_pixel_x(image, i);
    size_t y = get_pixel_y(image, i);
    size_t sum_r=0,sum_g=0,sum_b=0,count=0;
    pixel_t tmp_pixel = {0, 0, 0};
    for (size_t ky = y < 0 + ko ? 0 : y - ko; ky <= y + ko; ky++) {
      for (size_t kx = x < 0 + ko ? 0 : x - ko; kx <= x + ko; kx++) {
        pixel_t* pixel = get_pixel(image, kx, ky);
        if (!pixel) {
          fprintf(stderr, "ppm_reader: apply_box_blur (get_pixel)\n");
          vec_free(tmp_pixels);
          return;
        }
        sum_r+=pixel->r;
        sum_g+=pixel->g;
        sum_b+=pixel->b;
        count++;
      }
    }
    if (count == 0) {
      fprintf(stderr, "ppm_reader: apply_box_blur (count == 0)\n");
    }
    tmp_pixel.r = sum_r/count;
    tmp_pixel.g = sum_g/count;
    tmp_pixel.b = sum_b/count;
    clamp_pixel(&tmp_pixel, image->max);
    vec_push(tmp_pixels, &tmp_pixel);
  }
  if (!vec_copy(image->pixels, tmp_pixels)) {
    fprintf(stderr, "ppm_reader: apply_box_blur (vec_copy)\n");
  }
  vec_free(tmp_pixels);
}
