#!/bin/bash

./setsched PSN-EDF

rm -f log.txt

COLORS="0x00000001 0x0000ffff 0xffffffff"
WSS_MB=6

WSS=$(expr $WSS_MB \* 1024)

for C in $COLORS; do
echo "COLORS=$C" | tee -a log.txt

echo "./ca_spin -p 1 -P $C -l 20 -S $WSS -f 1 -r 0 500 1000 10" | tee -a log.txt
./ca_spin -p 1 -P $C -l 20 -S $WSS -f 1 -r 1 500 1000 10 | tee -a log.txt
done

