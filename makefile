CC=gcc
ASMBIN=nasm
CFLAGS= -m64 -Wall
LDFLAGS=-L/usr/lib -lallegro -lallegro_image -lallegro_primitives
INCLUDE=-I. -I/usr/include/allegro5

all : asm cc link
asm :
	$(ASMBIN) -o func.o -f elf64 -g -l func.lst func.asm
cc :
	$(CC) $(CFLAGS) -c -g -O0 main.c -std=c99 
link :
	$(CC) $(CFLAGS) -g -o program main.o func.o $(INCLUDE) $(LDFLAGS)
gdb :
	gdb program
clean :
	rm *.o
	rm *.lst
	rm program
debug :	all gdb
