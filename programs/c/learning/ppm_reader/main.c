#include "input.h"
#include "ppm_processor.h"
#include "tsring.h"
#include "vec.h"
#include <bits/time.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

#define loop(x) for (size_t i = 0; i < x; i++)

#define ARRAY_LEN(arr) (sizeof(arr) / sizeof((arr)[0]))

int main(int argc, char *argv[]) {

  if (argc < 3) {
    fprintf(stderr, "Usage: %s <input> <output>\n", argv[0]);
    return 0;
  }

  FILE *file = fopen(argv[1], "r");
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

  image_t image = {
      .pixels = vec_new_t(pixel_t, 0), .width = 0, .height = 0, .max = 0};

  clock_t start = clock();

  parse_file(content, &image);

  clock_t end = clock();

  printf("Parse time: %.2lf ms\n",
         ((double)(end - start) / CLOCKS_PER_SEC) * 1000);

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
    status = input_get_menu_choice(
        &choice,
        "====================================================\n Choice {}: ",
        main_menu, ARRAY_LEN(main_menu), NULL);
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
    case 0: {
      printf("\nProcessing...");
      apply_grayscale(&image);
      printf("\rApplied Grayscale filter Successfully!    \n\n");
      goto main_menu;
      break;
    }
    case 1: {
      printf("\nProcessing...");
      apply_invert(&image);
      printf("\rApplied Invert Colors filter Successfully!    \n\n");
      goto main_menu;
      break;
    }
    case 2: {
      hsv_t hsv_offset = {
        .h = 0,
        .s = 0,
        .v = 0
      };

      input_get_float(&hsv_offset.h, "Enter Hue offset {}:", &(float){0.0}, &(float){360.0}, &(float){0.0});

      input_get_float(&hsv_offset.s, "Enter Saturation offset {}:", &(float){-1.0}, &(float){1.0}, &(float){0.0});

      input_get_float(&hsv_offset.v, "Enter Value offset {}:", &(float){-1.0}, &(float){1.0}, &(float){0.0});

      printf("\nProcessing...");
      apply_hsv_adjustment(&image, &hsv_offset);
      printf("\rApplied HSV Adjustment Successfully!    \n\n");
      goto main_menu;
      break;
    }
    case 3: {
      printf("\nProcessing...");
      apply_box_blur(&image);
      printf("\rApplied Box blur filter Successfully!    \n\n");
      goto main_menu;
      break;
    }
    case 4: {
      printf("\nSaving to %s...\n", argv[2]);
      if (!save_ppm(argv[2], &image)) {
        fprintf(stderr, "\nFailed saving to %s\n\n", argv[2]);
      } else {
        printf("\nSuccessfully saved to %s\n\n", argv[2]);
      }
      goto main_menu;
      break;
    }
    default: {
      printf("\nQuitting...\n");
      goto clean_up;
    }
  }

  err = 0;

clean_up:
  vec_free(image.pixels);
  string_free(content);
  return err;
}
