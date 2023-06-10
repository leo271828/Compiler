#!/bin/bash
FILENAME=test
OUTPUT=tmp.out
clear
make clean

# make
# ./mycompiler < input/$FILENAME.go 
# make -s Main.class
# make -s run
make
./mycompiler < input/$FILENAME.go #>| $OUTPUT 
# clear
java -jar jasmin.jar hw3.j 
echo "Input file: $FILENAME.go"
java Main > $OUTPUT
# diff -y $OUTPUT answer/$FILENAME.out