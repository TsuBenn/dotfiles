CC = gcc
CFLAGS = -Wall -Wextra -g -fsanitize=address,undefined
BIN = cgrep

all: build/$(BIN)

build/$(BIN): main.c ../string/tsring.c ../string/tsring.h
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ main.c ../string/tsring.c

main: build/$(BIN)
	./build/$(BIN)

test: all
	./build/$(BIN) woman -f input.txt

clean:
	rm -rf build

.PHONY: all test clean
