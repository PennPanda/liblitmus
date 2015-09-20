#!/bin/bash

OUTFILE=test.txt
rm -f $OUTFILE
touch $OUTFILE

for S in $(seq 1 15); do
SS=$(expr $S \* 64)

LOGFILE=test_${SS}.out
rm -f $LOGFILE
touch $LOGFILE

for I in $(seq 1 15); do
echo "WSS=$SS, C=$I"
echo "WSS=$SS, C=$I" >> $OUTFILE
echo "WSS=$SS, C=$I" >> $LOGFILE

./rtspin_cache -p 0 -S $SS -I 5 -C $I 900 1000 30 | \ 
tee -a $LOGFILE | \
awk -f t.awk | \
tee -a $OUTFILE 

done

done

