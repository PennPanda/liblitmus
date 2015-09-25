#!/bin/bash

SCHEDULER=PSN-EDF
CACHE_INIT=0xffff
CPU=3
LOOP=10

CP=$1
WSS=$2
SPARSE=$3

if [ -z "$CP" ]; then
echo "Usage: ./flush_cache_one.sh {CP} [{WSS}] [{SPARSE}]"
echo "        CP = cache partition (1 - 16)"
echo "        WSS = array size in KB (default = CP *64 KB)"
echo "        SPARSE = cache partition spreadness (0=continuous(default), 1=sparse)"
exit 0
fi

if [ -z "$WSS" ]; then
WSS=$(expr $CP \* 64)
fi

if [ -z "$SPARSE" ]; then
SPARSE=0
SPARSE_OPT=
else
SPARSE=1
SPARSE_OPT="-s"
fi

echo 0 > /proc/sys/litmus/l1_prefetch
echo 0 > /proc/sys/litmus/l2_data_prefetch
echo 0 > /proc/sys/litmus/l2_prefetch_hint
echo 0 > /proc/sys/litmus/l2_double_linefill

echo ${CACHE_INIT} > /proc/sys/litmus/C0_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C0_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C1_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C1_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C2_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C2_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C3_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C3_LB_way

../setsched ${SCHEDULER}

declare -A lock

#continuous
lock[0,1]="0x0001"
lock[0,2]="0x0003"
lock[0,3]="0x0007"
lock[0,4]="0x000f"
lock[0,5]="0x001f"
lock[0,6]="0x003f"
lock[0,7]="0x007f"
lock[0,8]="0x00ff"
lock[0,9]="0x01ff"
lock[0,10]="0x03ff"
lock[0,11]="0x07ff"
lock[0,12]="0x0fff"
lock[0,13]="0x1fff"
lock[0,14]="0x3fff"
lock[0,15]="0x7fff"
lock[0,16]="0xffff"

#sparse
lock[1,1]="0x1000"
lock[1,2]="0x1100"
lock[1,3]="0x1110"
lock[1,4]="0x1111"
lock[1,5]="0x5111"
lock[1,6]="0x5511"
lock[1,7]="0x5551"
lock[1,8]="0x5555"
lock[1,9]="0xd555"
lock[1,10]="0xdd55"
lock[1,11]="0xddd5"
lock[1,12]="0xdddd"
lock[1,13]="0xfddd"
lock[1,14]="0xffdd"
lock[1,15]="0xfffd"
lock[1,16]="0xffff"

declare -A olock

olock[0,0]="0xffff"
olock[0,1]="0xfffe"
olock[0,2]="0xfffc"
olock[0,3]="0xfff8"
olock[0,4]="0xfff0"
olock[0,5]="0xffe0"
olock[0,6]="0xffc0"
olock[0,7]="0xff80"
olock[0,8]="0xff00"
olock[0,9]="0xfe00"
olock[0,10]="0xfc00"
olock[0,11]="0xf800"
olock[0,12]="0xf000"
olock[0,13]="0xe000"
olock[0,14]="0xc000"
olock[0,15]="0x8000"
olock[0,16]="0x0000"

olock[1,0]="0xffff"
olock[1,1]="0xefff"
olock[1,2]="0xeeff"
olock[1,3]="0xeeef"
olock[1,4]="0xeeee"
olock[1,5]="0xaeee"
olock[1,6]="0xaaee"
olock[1,7]="0xaaae"
olock[1,8]="0xaaaa"
olock[1,9]="0x2aaa"
olock[1,10]="0x22aa"
olock[1,11]="0x222a"
olock[1,12]="0x2222"
olock[1,13]="0x0222"
olock[1,14]="0x0022"
olock[1,15]="0x0002"
olock[1,16]="0x0000"

echo ${olock[$SPARSE,$CP]} > /proc/sys/litmus/C0_LA_way
echo ${olock[$SPARSE,$CP]} > /proc/sys/litmus/C1_LA_way
echo ${olock[$SPARSE,$CP]} > /proc/sys/litmus/C2_LA_way
echo ${olock[$SPARSE,$CP]} > /proc/sys/litmus/C3_LA_way

echo ${lock[$SPARSE,$CP]} > /proc/sys/litmus/C${CPU}_LA_way

../flush_cache -p $CPU -l $LOOP -C $CP -r 0 -S $WSS ${SPARSE_OPT} 900 1000 5


