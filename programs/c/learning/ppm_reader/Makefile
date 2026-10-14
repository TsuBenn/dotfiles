CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined
BIN = ppm_reader

all: build/$(BIN)

build/$(BIN): main.c tsring.c tsring.h vec.c vec.h input.c input.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c tsring.c vec.c input.c

main: build/$(BIN)
	./build/$(BIN)

test: all
	./build/$(BIN)

clean:
	rm -rf build

.PHONY: all test clean
