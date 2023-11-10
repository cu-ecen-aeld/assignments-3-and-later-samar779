CC = gcc
CROSS_COMPILE ?=

ifeq ($(CROSS_COMPILE),aarch64-none-linux-gnu-)
    CC = $(CROSS_COMPILE)gcc
endif

.PHONY: all clean

all: writer

writer: writer.o
	$(CC) -o writer writer.o

writer.o: writer.c
	$(CC) -c writer.c

clean:
	rm -f writer writer.o
