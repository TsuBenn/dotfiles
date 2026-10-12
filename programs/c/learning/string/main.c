#include <stdio.h>

#include "tsring.h"

int main() {

  string_t* string = string_from("Hello, World\n");
  string_t* pat = string_from("Hello");

  printf("%d\n", string_contains_string(string, pat));

  string_free(string);
  string_free(pat);

  return 0;
}
