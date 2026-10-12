CC = gcc
CFLAGS = -Wall -Wextra -Wpedantic -g -fsanitize=address,undefined

all: build/main build/vec_test

build/main: vec.c vec.h main.c
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ vec.c main.c

build/vec_test: vec.c vec.h vec_test.c
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ vec.c vec_test.c

test: all
	./build/vec_test
	./build/main

clean:
	rm -rf build

.PHONY: all test clean
