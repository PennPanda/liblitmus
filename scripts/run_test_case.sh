#!/bin/bash
# cat /dev/litmus/log > debug.txt &
source read_status.sh
source test_case_list.sh

# system crash due to lack of memory when we enable IPI trace with st_trace
FLAG_TRACE_IPI=0
FLAG_FTCAT_FIFO=0
ST_TRACE_PATH=/dev/shm

CASE=$1
DUR=$2
OPT_WAIT=$3
SCHED=$4
LOG=/root/debug_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}.txt
ST_TRACE_NAME=trace_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}
ST_MSG_TRACE_NAME=trace_msg_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}
LITMUS_STATUS_FILE=/tmp/litmus_status.txt
FILE_RANDOM=/tmp/random
TASKNUM=0
MAX_CHECK_STATUS=10 # we check if system is idle by MAX_CHECK_STATUS times
util=0 #utilization of released tasks

check_system_idle() {
	for((i=1; i<${MAX_CHECK_STATUS}; i+=1));do
		cat /proc/litmus/stats > ${LITMUS_STATUS_FILE}
		has_remain_task ${LITMUS_STATUS_FILE}
		running=$?
		if [[ "${running}" = "0" ]]; then
			break;
		fi
		sleep $(( ${i} * 5 ))
	done
}

if [[ -z "${CASE}" || -z "${DUR}" || -z "${OPT_WAIT}" || -z "${SCHED}" ]];then
	echo "[Usage] run_test_case test_case_id duration wait sched"
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
sudo killall rtspin
sudo killall ca_spin
sudo killall ca_thrash
sudo killall cpu_spin
sudo killall st_trace
sudo killall ftcat
sudo rm -f ${LOG}
sudo killall cat
sleep 1
echo "set the environment"
./init.sh ${SCHED}
sleep 1
echo "reset the scheduler"
setsched Linux
setsched ${SCHED}
showsched
sudo cat /dev/litmus/log > ${LOG} &
echo "Now start test case ${CASE}"
# start feather trace
./scripts/st_trace -s ${ST_TRACE_NAME} ${ST_TRACE_PATH} & 
sleep 2
if [[ ${FLAG_FTCAT_FIFO} == "1" ]];then
	echo "set ftcat to highest priority in FIFO scheduler"
	./scripts/set_fifo.sh ftcat
	sleep 1
fi

# start feather message trace for IPI trace logs
if [[ ${FLAG_TRACE_IPI} == "1" ]]; then
ftcat /dev/litmus/ft_msg_trace0 SEND_RESCHED_START SEND_RESCHED_END > ${ST_MSG_TRACE_NAME}-0.bin &
ftcat /dev/litmus/ft_msg_trace1 SEND_RESCHED_START SEND_RESCHED_END > ${ST_MSG_TRACE_NAME}-1.bin &
ftcat /dev/litmus/ft_msg_trace2 SEND_RESCHED_START SEND_RESCHED_END > ${ST_MSG_TRACE_NAME}-2.bin &
ftcat /dev/litmus/ft_msg_trace3 SEND_RESCHED_START SEND_RESCHED_END > ${ST_MSG_TRACE_NAME}-3.bin &
fi

# now at liblitmus folder
# Run one test case
test_case ${CASE}

sleep 1
if [[ "${WAIT}" == "-w" ]]; then
	./release_ts -f ${TASKNUM} &
fi
sleep ${DUR}

check_system_idle

if [[ "${i}" == "${MAX_CHECK_STATUS}" ]]; then
	echo "[ATTENTION] Has task remaining in system after experiment!"
	echo "Force all RT tasks exit..."
	echo "killall -9 rtspin"
	killall -9 rtspin
	check_system_idle
fi

sleep 5
#killall cat
killall st_trace
killall ftcat
killall cat
sleep 1

for((i=0; i<10; i+=1));do
	FTCAT_NUM=$(ps -ef | grep "ftcat" | grep -v "grep" | wc -l)
	if [[ "${FTCAT_NUM}" != "0" ]]; then
		sleep $i;
		echo "Wait ftcat being killed"
	fi
done

# move st_trace .bin to trace_bin folder
mv ${ST_TRACE_PATH}/*${ST_TRACE_NAME}*.bin ./trace_bin/

echo "[Experiment DONE] test=${CASE} dur=${DUR} log=${LOG}"
echo "---------------------------------"
echo "start parsing data"
cd scripts
./parse_bin.sh ${ST_TRACE_NAME}
./find_ddl_miss.sh ${ST_TRACE_NAME}
echo "[Data Analysis DONE] test=${CASE} dur=${DUR} log=${LOG} trace=${ST_TRACE_NAME}"
echo "---------------------------------"
