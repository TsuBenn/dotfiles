#include <stdio.h>

#include "tsring.h"

int main() {

  string_t* string = string_from("Hello, World\n");

  printf("%s", string->buf);

  string_free(string);

  return 0;
}
