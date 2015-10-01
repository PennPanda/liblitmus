#!/bin/bash

DATA_FOLDER=calib_data
TARGET_DATA=$1

OUT_DATA=result.txt

cd ..

if [ -z "$TARGET_DATA" ]; then
LAST_DATA=$(ls $DATA_FOLDER | sort -n | tail -1)

if [ -z "$LAST_DATA" ]; then
exit 0
fi

TARGET_DATA=$LAST_DATA
fi

cd $DATA_FOLDER

if [ ! -d "$TARGET_DATA" ]; then
echo "No such data folder: $DATA_FOLDER/$TARGET_DATA"
echo "Usage: $0 [folder]"
cd ..
exit 0
fi

cd $TARGET_DATA

printf "%-25s, %-10s, %-10s, %-10s, %-10s\n" "CASE" "avg" "min" "max" "dmiss" > $OUT_DATA

# get base test case from log filename
LOGS=$(ls *_log | sort -t_ -k3,3n -k5,5n)

for LOG in $LOGS; do
CASE=$(echo $LOG | cut -d_ -f1-5)
printf "%-25s" "$CASE" | tee -a $OUT_DATA

JOB_STAT_LOG=${CASE}-jobs.txt
st_job_stats st-${CASE}-?.bin 2>& 1 > $JOB_STAT_LOG

DATA=$(../../calc2.py $JOB_STAT_LOG | tr "," "\n")
for D in $DATA; do
printf ", %10s" $D | tee -a $OUT_DATA
done
echo "" | tee -a $OUT_DATA

done

cd ../..

