#!/bin/bash
CASE_START=$1
CASE_END=$2
DUR=$3

if [[ -z ${CASE_START} || -z "${CASE_END}" || -z "${DUR}" ]]; then
	echo "[Usage] ./check_sched_seq_batch.sh test_id_start test_id_end duration (inclusive)"
	exit 1;
fi

for((i=${CASE_START}; i<=${CASE_END}; i+=1));do
	./check_sched_seq.sh ${i} ${DUR}
done

echo "========================"
echo "All tests are done! Check the trace result"
