#!/bin/bash

declare -a Algs=( "GSN-FPCA2" "GSN-EDF" "GSN-NPFPCA" "GSN-FPCANW" "GSN-FP" )
declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
num_tasks_min=50
num_tasks_step=50
num_tasks_max=100
case_min=0
case_step=1
case_max=1
DUR=10 #seconds

for ((case=${case_min}; case<=${case_max}; case+=1));do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=50));do
			echo "./run_overhead_measurement.sh ${case} 30 0 ${alg} ${type} ${num_tasks}"
			./run_overhead_measurement.sh ${case} 30 0 ${alg} ${type} ${num_tasks}
		done
		./move_result.sh
	done
done
done

echo "check the overhead value under ../trace_oh"
