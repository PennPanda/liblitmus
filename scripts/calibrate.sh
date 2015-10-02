#!/bin/bash

get_next_folder() {
BASE_FOLDER=$1

LAST_FOLDER=$(ls $BASE_FOLDER/ | sort -n | tail -1)

if [ "$LAST_FOLDER" == "" ]; then
	return 1
fi

return $(expr $LAST_FOLDER + 1)
}

# default values:

LOOP_BASE=1
CPS="1 8 16"
WCETS="10 100 1000"
# total job count
JOBS=100

SCHEDULER=GSN-FPCA

BASE_FOLDER=calib_data

# move to parent directory
cd ..

mkdir -p $BASE_FOLDER

get_next_folder $BASE_FOLDER
OUT_FOLDER=$BASE_FOLDER/$?
echo $OUT_FOLDER

mkdir -p $OUT_FOLDER

./init.sh $SCHEDULER

for CP in $CPS; do

for WCET in $WCETS; do

WSS=$(expr $CP \* 64)
LOOP=$(expr $WCET / 10)

# PERIOD = $WCET * 2
PERIOD=$(expr $WCET \* 2)

# DURATION = $PERIOD * job counts
DURATION_MS=$(expr $PERIOD \* $JOBS)
DURATION=$(expr $DURATION_MS / 1000)
if [ $DURATION -eq 0 ]; then
DURATION=1
fi

# add few seconds to duration
DURATION=$(expr $DURATION + 2)

TRACE_PREFIX=calib_CP_${CP}_WCET_${WCET}
APP_LOG=${TRACE_PREFIX}_log

echo "CP=$CP, WCET=$WCET, WSS=$WSS, LOOP=$LOOP, PERIOD=$PERIOD, DURATION=$DURATION" | tee $APP_LOG

./ca_spin -w -r 1 -S $WSS -l $LOOP -C $CP $WCET $PERIOD $DURATION 2>& 1 | tee -a $APP_LOG &
MAIN_PID=$!

st_trace -s $TRACE_PREFIX &
TRACE_PID=$!

./release_ts -f 1

sleep $DURATION

# check the process is terminated
while [ 1 ]; do

kill -0 $MAIN_PID 2> /dev/null

if [ $? -ne 0 ]; then
break
fi

sleep 1
done

# send SIGUSR1 to st_trace
kill -10 $TRACE_PID 2> /dev/null

# check the process is terminated
while [ 1 ]; do

kill -0 $TRACE_PID 2> /dev/null

if [ $? -ne 0 ]; then
break
fi

sleep 1
done

# move trace file to outfolder
mv -f st-${TRACE_PREFIX}-?.bin $OUT_FOLDER
mv -f ${APP_LOG} $OUT_FOLDER

done

done

