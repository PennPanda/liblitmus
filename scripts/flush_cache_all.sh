#!/bin/bash

SPARSE=$1
FIX_WSS=$2

if [ "$SPARSE" == "1" ]; then
SPARSE=1
else
SPARSE=0
fi

OUTFILE=../result_flush_cache_all${SPARSE}.txt
rm -f $OUTFILE
touch $OUTFILE

for CP in $(seq 1 16); do

if [ "$FIX_WSS" != "" ]; then
WSS=$FIX_WSS
else
WSS=$(expr $CP \* 64)
fi

./flush_cache_one.sh $CP $WSS $SPARSE | tee -a $OUTFILE


done

