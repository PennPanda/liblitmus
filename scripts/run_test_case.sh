#!/bin/bash
# cat /dev/litmus/log > debug.txt &
source read_status.sh

CASE=$1
DUR=$2
OPT_WAIT=$3
SCHED=$4
LOG=/root/debug_test${CASE}_dur${DUR}_wait${OPT_WAIT}_sched${SCHED}.txt
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
sudo rm ${LOG}
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

#now at liblitmus folder
if [[ ${CASE} == 1 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 0 &
fi

if [[ ${CASE} == 98 ]]; then
	./ca_spin ${WAIT} -q 1 -C 16 -S 384 -l 100 -r 1 400 1000 ${DUR} &
fi

if [[ ${CASE} == 99 ]]; then
	./ca_spin ${WAIT} -q 1 -C 15 -S 384 -l 100 -r 1 400 1000 ${DUR} &
fi

if [[ ${CASE} == 100 ]]; then
	./ca_spin ${WAIT} -q 1 -C 8 -S 384 -l 100 -r 1 400 1000 ${DUR} &
fi

if [[ ${CASE} == 101 ]]; then
	./ca_spin ${WAIT} -q 1 -C 16 -S 384 -l 100 -r 1 400 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 0 -l 1000 -r 0 900 1000 ${DUR} &
fi

if [[ ${CASE} == 102 ]]; then
	./ca_spin ${WAIT} -q 1 -C 15 -S 384 -l 100 -r 1 400 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 1 -l 1000 -r 0 999 1000 ${DUR} &
fi

if [[ ${CASE} == 103 ]]; then
	./ca_spin ${WAIT} -q 1 -C 8 -S 384 -l 100 -r 1 400 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 8 -l 1000 -r 0 999 1000 ${DUR} &
fi

if [[ ${CASE} == 104 ]]; then
	./ca_spin ${WAIT} -q 1 -C 8 -S 384 -l 100 -r 1 400 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
fi

if [[ ${CASE} == 2 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 16 &
fi

if [[ ${CASE} == 3 ]]; then
	./rtspin 30 1000 $DUR -q 2 -C 8 &
	./rtspin 900 1000 $DUR -q 99 -C 1 &
fi

# Check space constraint is valid
# RT tasks cannot run at the same time
if [[ ${CASE} == 4 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 15 &
	./rtspin 100 300 $DUR -q 3 -C 2 &
fi

# Check preempt multiple tasks via cache
# Both tasks can be preempted at the same time
if [[ ${CASE} == 5 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 15 &
	./rtspin 100 300 $DUR -q 3 -C 2 &
	./rtspin 100 300 $DUR -q 4 -C 3 &
fi

# Check if allow priority inversion
# T2 cannot run with other tasks
# If allow PI, T1 preempt T2 and allow other to run
# If not allow PI, T1 preempt T2 and others wait
if [[ ${CASE} == 6 ]]; then
	./rtspin 50  150 $DUR -q 1 -C 2 &
	./rtspin 100 200 $DUR -q 2 -C 15 &
	./rtspin 100 300 $DUR -q 3 -C 2 &
	./rtspin 100 400 $DUR -q 4 -C 3 &
	./rtspin 100 600 $DUR -q 5 -C 3 &
fi

# Check the case when a RT task preempt another RT task via CPU only
# scheduler should add the preempted task back to ready_queue
if [[ ${CASE} == 7 ]]; then
	./rtspin 50  150 $DUR -q 1 -C 1 ${WAIT} &
	./rtspin 150 200 $DUR -q 2 -C 1 ${WAIT} &
	./rtspin 150 300 $DUR -q 3 -C 1 ${WAIT} &
	./rtspin 150 400 $DUR -q 4 -C 1 ${WAIT} &
	./rtspin 150 600 $DUR -q 5 -C 1 ${WAIT} &
	./rtspin 150 600 $DUR -q 6 -C 1 ${WAIT} &
fi

# Pressure test with many tasks
if [[ ${CASE} == 8 ]]; then
	#for((i=1; i<255;i+=1));do
	TASKNUM=0;
	for((i=1; i<200;i+=1));do
		period=$(( 500 + $(( ${i} * 10 )) ))
		cp=`expr ${i} % 8 + 1`
		#exe=10, 11 #2 rtspins left
		#exe=5 or 1 #no rtspin left
		exe=10
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
		TASKNUM=$(( ${TASKNUM} + 1 ))
	done
fi

if [[ ${CASE} == 9 ]]; then
	TASKNUM=0;
	#for((i=1; i<255;i+=1));do
	for((i=1; i<200;i+=1));do
		period=$(( 500 + $(( ${i}  )) ))
		cp=`expr ${i} % 16 + 1`
		#exe=10, 11 #2 rtspins left
		#exe=5 or 1 #no rtspin left
		exe=10
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
		TASKNUM=$(( ${TASKNUM} + 1 ))
	done
fi

# 390 tasks but only use 3.9 cores
if [[ ${CASE} == 10 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=390;i+=1));do
		period=$(( $(( ${i} * 100 )) ))
		cp=`expr ${i} % 16 + 1`
		exe=1
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
	done
fi

# at most 100 light tasks with 'random' param; taskset utilization 350%
if [[ ${CASE} == 11 ]]; then
	for((i=1; i<=350;i+=1));do
		shuf -i 10-10000 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 16`
		shuf -i 1-5 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 100 ))
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
		if [[ ${util} -ge 350 ]]; then
			break;
		fi
	done
fi

# at most 100 medium tasks with 'random' param; taskset utilization 350%
if [[ ${CASE} == 12 ]]; then
	for((i=1; i<=350;i+=1));do
		shuf -i 10-10000 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 16`
		shuf -i 5-50 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 100 ))
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
		if [[ ${util} -ge 350 ]]; then
			break;
		fi
	done
fi

# at most 100 heavy tasks with 'random' param; taskset utilization 350%
if [[ ${CASE} == 13 ]]; then
	for((i=1; i<=350;i+=1));do
		shuf -i 10-10000 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 16`
		shuf -i 51-100 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 100 ))
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
		if [[ ${util} -ge 350 ]]; then
			break;
		fi
	done
fi

# 500 tasks with 'random' param; taskset utilization 500%
if [[ ${CASE} == 14 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=500;i+=1));do
		shuf -i 10-10000 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 16`
		shuf -i 1-100 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 100 ))
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
		if [[ ${util} -ge 500 ]]; then
			break;
		fi
	done
fi

sleep 1
if [[ "${WAIT}" == "-w" ]]; then
	./release_ts -f ${TASKNUM} &
fi
sleep ${DUR}

check_system_idle

if [[ "${i}" == "${MAX_CHECK_STATUS}" ]]; then
	echo "[ATTENTION] Has task remaining in system after experiment!"
	echo "Force all RT tasks exit..."
	killall -9 rtspin
	check_system_idle
fi

#killall cat
echo "[DONE] test=${CASE} dur=${DUR} log=${LOG}"
echo "---------------------------------"
