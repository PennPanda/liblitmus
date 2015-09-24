#!/bin/bash
# This file will be included by run_test_case.sh

has_remain_task() {
	FILE=$1
	LINENUM=0;
	NUM_READY_TASK=-1;
	NUM_RELEASE_TASK=-1;
	echo "check remaining task in file ${FILE}"
	while read first second third fourth fifth nonimportant
	do
		LINENUM=$(( ${LINENUM}+1 ));
		#echo "LINENUM=${LINENUM}"
		if [[ ${LINENUM} -eq 1 ]];then
			NUM_READY_TASK=${fourth};
		fi
		if [[ ${LINENUM} -eq 2 ]];then
			NUM_RELEASE_TASK=${fifth}
		fi
	done < ${FILE}

	#echo "NUM_READY_TASK=${NUM_READY_TASK} NUM_RELEASE_TASK=${NUM_RELEASE_TASK}"
	if [[ ${NUM_READY_TASK} -eq 0 && ${NUM_RELEASE_TASK} -eq 0 ]];then
		return 0;
	else
		return 1;
	fi
}

test_has_remain_task() {
	echo "Input file ${FILE}"
	has_remain_task
	idlesys=$?
	if [[ ${idlesys} -eq 0 ]]; then
		echo "has no remaining task"
	else
		echo "has remaining task"
	fi
}


