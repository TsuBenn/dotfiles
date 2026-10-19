CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined -o3
CDEFS = -lm
BIN = ppm_reader

all: build/$(BIN)

build/$(BIN): main.c tsring.c tsring.h vec.c vec.h input.c input.h ppm_processor.h ppm_processor.c
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c tsring.c vec.c input.c ppm_processor.c $(CDEFS)

main: build/$(BIN)
	./build/$(BIN)

test: all
	./build/$(BIN)

clean:
	rm -rf build

.PHONY: all test clean
