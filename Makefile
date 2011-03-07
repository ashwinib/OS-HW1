all: p3

p3: p3.c
	gcc -o p3 -lpthread -lrt p3.c
