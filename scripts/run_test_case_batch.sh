#!/bin/bash
CASE_START=$1
CASE_END=$2
DUR=$3

if [[ -z ${CASE_START} || -z "${CASE_END}" || -z "${DUR}" ]]; then
	echo "[Usage] ./run_test_case_batch test_id_start test_id_end duration (inclusive)"
	echo "test id: 1 - 6"
	exit 1;
fi

echo "Test case ${CASE_START}-${CASE_END} for ${DUR}s"

for((i=${CASE_START}; i<=${CASE_END}; i+=1));do
	echo "./run_test_case.sh ${i} ${DUR}"
	./run_test_case.sh ${i} ${DUR}
done

echo "========================"
echo "All tests are done! Check the trace result"
