#/bin/bash

clang -c hello.c -o hello.o
ar rcs libhello.a hello.o
rm hello.o
