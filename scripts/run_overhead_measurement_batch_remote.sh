#!/bin/bash
# run on desktop to walk around the memory leak issue in ftcat
# Experiment: DUR=30 case_min=0, case_step=1, case_max=10, types=light, Algs=5algs, RTTASK=3kinds <-- 20 hours

ROOT=/home/ubuntu/mengxu/liblitmus/scripts
WAIT=0
#Three types of workload: rtspin (cpu), ca_spin (cache read), ca_spinwrite (cache write)
rttask=rtspin
declare -a RTTASKS=( "rtspin" "ca_spin" "ca_spinwrite" )
#declare -a Algs=( "GSN-FPCA2" "GSN-EDF" )
#declare -a Algs=( "GSN-FPCA2" "GSN-EDF" "GSN-NPFPCA" "GSN-FPCANW" "GSN-FP" )
declare -a Algs=( "GSN-FPCA2" "GSN-EDF" "GSN-NPFPCA" )
#declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
declare -a TYPES=( "Uniform_Heavy" )
num_tasks_min=50
num_tasks_step=50
num_tasks_max=450
case_min=0
case_step=1
case_max=9
DUR=30 #seconds #each experiment takes about 2.7min
tmp=0;

for ((case=${case_min}; case<=${case_max}; case+=1));do
for((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=50));do
for rttask in "${RTTASKS[@]}"
do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		# Not rerun if we have the data
		tmp=`ls trace_bin/oh-trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${rttask}-*.bin | wc -l`
        echo ${tmp}
		#if [[ "${tmp}" == "19" ]];then
		if [[ "${tmp}" != "0" ]];then
			echo "[FOUND] ${rttask} ${case} ${type} ${alg}"
			echo "[NOT RERUN THIS EXPERIMENT]"
			continue;
		fi
		#sleep 10
		tmp=0;
		while [[ 1 ]]; do
			tmp=$(( ${tmp} +1 ))
			echo "ping board1 ${tmp} times"
			ping -c 1 board1 
			if [[ "$?" == "0" ]]; then
				break;
			fi
		done
		echo "./run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${rttask}"
		ssh root@board1 "source /home/ubuntu/.bashrc; source /root/.bashrc; cd ${ROOT}; ./run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${rttask}" > /dev/null &
        echo "sleep $(( ${DUR} + 10 ))"
        sleep $(( ${DUR} + 10 ))
        ssh root@board1 "killall -9 ./run_overhead_measurement.sh"
        ssh root@board1 "killall -9 ./run_overhead_measurement.sh"
		#echo "ssh root@board1 "source /home/ubuntu/.bashrc; source /root/.bashrc; cd ${ROOT}; ./run_overhead_measurement_postprocess.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${rttask}" > /dev/null"
		#ssh root@board1 "source /home/ubuntu/.bashrc; source /root/.bashrc; cd ${ROOT}; ./run_overhead_measurement_postprocess.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${rttask}" > /dev/null
		ssh root@board1 "${ROOT}/move_result.sh"
		ssh root@board1 "reboot"
		sleep 6
		echo "[Done] ${rttask} ${case} ${type} ${alg}"
		date
	done
done
done
done
done
echo "[All Overhead Measurement Done] check the overhead value under ../trace_oh"
