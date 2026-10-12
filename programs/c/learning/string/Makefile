CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined

all: build/main build/core_test

build/main: main.c tsring.c tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c tsring.c

build/core_test: core_test.c tsring.c tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ core_test.c tsring.c

main: build/main
	./build/main

test: all
	./build/main
	./build/core_test

clean:
	rm -rf build

.PHONY: all test clean
