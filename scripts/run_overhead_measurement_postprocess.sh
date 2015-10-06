#!/bin/bash
# cat /dev/litmus/log > debug.txt &
source read_status.sh
source overhead_measurement_list.sh 

# system crash due to lack of memory when we enable IPI trace with st_trace
FLAG_TRACE_IPI=1
FLAG_FTCAT_FIFO=1
FLAG_OH=1
ST_TRACE_PATH=/tmp/

CASE=$1
DUR=$2
OPT_WAIT=$3
SCHED=$4
TYPE=$5
NUM_TASKS=$6
RTTASK=$7
LOG=/root/debug_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}_type${TYPE}_numtasks${NUM_TASKS}_rt${RTTASK}.txt
ST_TRACE_NAME=trace_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}_type${TYPE}_numtasks${NUM_TASKS}_rt${RTTASK}
ST_MSG_TRACE_NAME=msg_trace_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}_type${TYPE}_numtasks${NUM_TASKS}_rt${RTTASK}
LITMUS_STATUS_FILE=/tmp/litmus_status.txt
FILE_RANDOM=/tmp/random
TASKNUM=0
MAX_CHECK_STATUS=2 # we check if system is idle by MAX_CHECK_STATUS times
util=0 #utilization of released tasks

check_system_idle() {
	for((i=1; i<${MAX_CHECK_STATUS}; i+=1));do
		cat /proc/litmus/stats > ${LITMUS_STATUS_FILE}
		has_remain_task ${LITMUS_STATUS_FILE}
		running=$?
		if [[ "${running}" = "0" ]]; then
			break;
		fi
		#sleep $(( ${i} * 5 ))
	done
}

if [[ -z "${CASE}" || -z "${DUR}" || -z "${OPT_WAIT}" || -z "${SCHED}" ]];then
	echo "[Usage] run_test_case test_case_id duration wait sched type num_task"
	exit 1;
fi

WAIT=""
if [[ "${OPT_WAIT}" == "1" ]];then
	WAIT="-w";
fi
if [[ "${OPT_WAIT}" == "0" ]];then
	WAIT="";
fi
echo "WAIT=${WAIT}"

cd ../
echo "---------------------------------"
echo "[START] I'm at "
pwd
echo "log=${LOG}"
echo "rm log and killall cat and rtspin"
for((j=1; j<450;j+=1));do
	#sudo killall -9 rtspin
	#sudo killall -9 ca_spin
	#sudo killall -9 ca_spinwrite
	#sudo killall -9 ca_thrash
	sudo killall -9 ${RTTASK}
	#sudo killall -9 cpu_spin
	#check_system_idle
	#system is idle
	#if [[ "${i}" != "${MAX_CHECK_STATUS}" ]]; then
	#	j+=1
	#fi
done
sudo killall st_trace
sudo killall ftcat
sudo rm -f ${LOG}
sudo killall cat

for((i=0; i<10; i+=1));do
	FTCAT_NUM=$(ps -ef | grep "ftcat" | grep -v "grep" | wc -l)
	if [[ "${FTCAT_NUM}" != "0" ]]; then
		sleep $i;
		echo "Wait ftcat being killed"
	fi
done

# move st_trace .bin to trace_bin folder
mv ${ST_TRACE_PATH}/*${ST_TRACE_NAME}*.bin ./trace_bin/
mv ${ST_TRACE_PATH}/*${ST_MSG_TRACE_NAME}*.bin ./trace_bin/

echo "[Experiment DONE] test=${CASE} dur=${DUR} log=${LOG}"
echo "---------------------------------"
echo "start parsing data"
cd scripts
./parse_bin.sh ${ST_TRACE_NAME} ${ST_MSG_TRACE_NAME}
#./find_ddl_miss.sh ${ST_TRACE_NAME}
echo "[Data Analysis DONE] test=${CASE} dur=${DUR} log=${LOG} trace=${ST_TRACE_NAME}"
echo "---------------------------------"
