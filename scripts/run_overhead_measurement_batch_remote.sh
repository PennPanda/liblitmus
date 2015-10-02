#!/bin/bash
# run on desktop to walk around the memory leak issue in ftcat

ROOT=/home/ubuntu/mengxu/liblitmus/scripts
#Three types of workload: rtspin (cpu), ca_spin (cache read), ca_spinwrite (cache write)
RTTASK=rtspin
declare -a Algs=( "GSN-FPCA2" "GSN-EDF" "GSN-NPFPCA" "GSN-FPCANW" "GSN-FP" )
declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
num_tasks_min=50
num_tasks_step=50
num_tasks_max=100
case_min=0
case_step=1
case_max=1
DUR=10 #seconds
tmp=0;

for ((case=${case_min}; case<=${case_max}; case+=1));do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=50));do
			tmp=0;
			while [[ 1 ]]; do
				tmp=$(( ${tmp} +1 ))
				echo "ping board1 ${tmp} times"
				ping -c 1 board1 
				if [[ "$?" == 0 ]]; then
					break;
				fi
			done
			echo "./run_overhead_measurement.sh ${case} 30 0 ${alg} ${type} ${num_tasks} ${RTTASK}"
			ssh root@board1 "${ROOT}/move_result.sh"
			ssh root@board1 "source /home/ubuntu/.bashrc; source /root/.bashrc; cd ${ROOT}; ./run_overhead_measurement.sh ${case} 30 0 ${alg} ${type} ${num_tasks} ${RTTASK}"
			ssh root@board1 "reboot"
			sleep 6
		done
		echo "[Done] ${case} ${type} ${alg}"
	done
done
done

echo "check the overhead value under ../trace_oh"
