#!/bin/bash

CASE=$1

cd ..
# check if the  register is correctly set
if [[ ${CASE} == 1 ]]; then
	./ca_spin -q 1 -p 1 -C 2 -M 0x3 -S 4096 -l 10 -r 1 -U 0 -f 1 200 200 30 
fi

if [[ ${CASE} == 2 ]]; then
	./ca_spin -q 1 -p 1 -C 8 -M 0xff -S 4096 -l 10 -r 1 -U 0 -f 1 200 200 30 
fi


