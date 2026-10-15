#include "tsring.h"
#include "vec.h"
#include <ctype.h>
#include <math.h>
#include <stddef.h>

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
      size_t avg_val = (pixel->r + pixel->b + pixel->b) / 3;
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

  // 0->r 1->g 3->b
  int max_color = 0;
  float nmax = 0;
  float nmin = 1;

  if (nr > nmax) {
    nmax = nr;
    max_color = 0;
  }
  if (ng > nmax) {
    nmax = ng;
    max_color = 1;
  }
  if (nb > nmax) {
    nmax = nb;
    max_color = 2;
  }

  if (nr < nmin)
    nmin = nr;
  if (ng < nmin)
    nmin = ng;
  if (nb < nmin)
    nmin = nb;

  float delta = nmax - nmin;

  hsv_t hsv;

  hsv.v = nmax;
  hsv.s = nmax ? delta / (nmax) : 0;

  switch (max_color) {
  case 0:
    hsv.h = 60 * fmodf((ng - nb) / delta, 6.0f);
    break;
  case 1:
    hsv.h = 60 * ((nb - nr) / delta + 2.0f);
    break;
  case 2:
    hsv.h = 60 * ((nr - ng) / delta + 4.0f);
    break;
  }

  if (hsv.h < 0.0f) {
    hsv.h += 360.0f;
  }

  return hsv;
}

pixel_t hsv_to_rgb(hsv_t *hsv, int max) {
  pixel_t pixel;

  if (hsv->s == 0.0f) {
    pixel.r = hsv->v * max;
    pixel.g = hsv->v * max;
    pixel.b = hsv->v * max;
    return pixel;
  }

  float c = hsv->s * hsv->v;
  float h_prime = fmodf(hsv->h / 60.0f, 6.0f);
  float x = c * (1.0f - fabsf(fmodf(h_prime, 2.0f) - 1.0f));
  float m = hsv->v - c;

  float r_prime = 0.0f, g_prime = 0.0f, b_prime = 0.0f;

  // Pick the mix based on which 60-degree sector hue falls into
  if (h_prime >= 0.0f && h_prime < 1.0f) {
    r_prime = c;
    g_prime = x;
    b_prime = 0.0f;
  } else if (h_prime >= 1.0f && h_prime < 2.0f) {
    r_prime = x;
    g_prime = c;
    b_prime = 0.0f;
  } else if (h_prime >= 2.0f && h_prime < 3.0f) {
    r_prime = 0.0f;
    g_prime = c;
    b_prime = x;
  } else if (h_prime >= 3.0f && h_prime < 4.0f) {
    r_prime = 0.0f;
    g_prime = x;
    b_prime = c;
  } else if (h_prime >= 4.0f && h_prime < 5.0f) {
    r_prime = x;
    g_prime = 0.0f;
    b_prime = c;
  } else {
    r_prime = c;
    g_prime = 0.0f;
    b_prime = x;
  }

  // Add back the baseline brightness and scale to final output
  pixel.r = (r_prime + m) * max;
  pixel.g = (g_prime + m) * max;
  pixel.b = (b_prime + m) * max;

  return pixel;
}

void hsv_add_hsv(hsv_t *hsv, hsv_t *other_hsv) {
  hsv->h += other_hsv->h;
  if (hsv->h > 360.0) {
    hsv->h -= 360;
  } else if (hsv->h < 0) {
    hsv->h += 360;
  }
  hsv->s += other_hsv->s;
  if (hsv->s > 1.0) {
    hsv->s = 1.0;
  } else if (hsv->s < 0) {
    hsv->s = 0.0;
  }
  hsv->v += other_hsv->v;
  if (hsv->v > 1.0) {
    hsv->v = 1.0;
  } else if (hsv->s < 0) {
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

void apply_box_blur(image_t *image) {}
