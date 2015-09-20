#!/bin/bash

lock[1]="0x0001"
lock[2]="0x0003"
lock[3]="0x0007"
lock[4]="0x000f"
lock[5]="0x001f"
lock[6]="0x003f"
lock[7]="0x007f"
lock[8]="0x00ff"
lock[9]="0x01ff"
lock[10]="0x03ff"
lock[11]="0x07ff"
lock[12]="0x0fff"
lock[13]="0x1fff"
lock[14]="0x3fff"
lock[15]="0x7fff"
lock[16]="0xffff"

olock[0]="0xffff"
olock[1]="0xfffe"
olock[2]="0xfffc"
olock[3]="0xfff8"
olock[4]="0xfff0"
olock[5]="0xffe0"
olock[6]="0xffc0"
olock[7]="0xff80"
olock[8]="0xff00"
olock[9]="0xfe00"
olock[10]="0xfc00"
olock[11]="0xf800"
olock[12]="0xf000"
olock[13]="0xe000"
olock[14]="0xc000"
olock[15]="0x8000"
olock[16]="0x0000"

OUTFILE=test.txt
rm -f $OUTFILE
touch $OUTFILE

for S in $(seq 1 15); do
SS=$(expr $S \* 64)
echo $SS
echo $SS >> $OUTFILE

for I in $(seq 1 15); do
echo ${olock[$I]} > /proc/sys/litmus/C0_LA_way
echo ${olock[$I]} > /proc/sys/litmus/C1_LA_way
echo ${olock[$I]} > /proc/sys/litmus/C2_LA_way
echo ${olock[$I]} > /proc/sys/litmus/C3_LA_way

./rtspin_cache -w -p 0 -S $SS -I 5 -C $I 900 1000 30 | awk -f t.awk >> $OUTFILE &

PID=$(pidof rtspin_cache)
CPU=$(ps -P --pid $PID | tail -1 | awk '{print $2}')
echo "PID=$PID, CPU=$CPU"
echo ${lock[$I]} > /proc/sys/litmus/C${CPU}_LA_way

./release_ts -f 1

while [ "$PID" != "" ]; do
sleep 1
PID=$(pidof rtspin_cache)
CPU=$(ps -P --pid $PID | tail -1 | awk '{print $2}')
echo "PID=$PID, CPU=$CPU"
done

done

done

