#!/bin/bash

declare -a Algs=( "GSN-EDF" )
#declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
declare -a TYPES=( "Uniform_Light" )
num_tasks_min=5
num_tasks_step=5
num_tasks_max=30
case_min=0
case_step=1
case_max=1
DUR=10 #seconds
WAIT=1 #release tasks at the same time?
IS_CAT=1 #evaluate on CAT?
RTTASK=ca_spin_v3_oh_measurement

for ((case=${case_min}; case<=${case_max}; case+=1));do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=50));do
			echo "./run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${RTTASK} ${IS_CAT}"
			./run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${RTTASK} ${IS_CAT}
		done
		./move_result.sh
	done
done
done

echo "check the overhead value under ../trace_oh"
