#!/bin/bash
PID=$1

if [[ ${PID} -lt 1 || ${PID} -ge 10000 ]]; then
	echo "${PID} is invalid"
	exit 1;
fi

echo ${PID} > /proc/sys/litmus/task_info
