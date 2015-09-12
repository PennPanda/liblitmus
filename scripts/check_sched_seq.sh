#!/bin/bash
DEST=./data
CASE=$1
DUR=$2
LOG=/root/debug_test${CASE}_dur${DUR}.txt
DEBUGLOG1=${DEST}/debug_test${CASE}_dur${DUR}_task_config.txt
DEBUGLOG2=${DEST}/debug_test${CASE}_dur${DUR}_task_preemption.txt

if [[ -z "${CASE}" ]];then
	echo "[Usage] check_sched_seq.sh test_case_id duration"
	exit 1;
fi

sudo cp ${LOG} ${DEST}
sudo grep "rt: adding rtspin" ${LOG} > ${DEBUGLOG1}
sudo grep "preempted by" ${LOG} > ${DEBUGLOG2}
