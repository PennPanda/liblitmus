#!/bin/bash
# cat /dev/litmus/log > debug.txt &
CASE=$1
DUR=$2
LOG=/root/debug_test${CASE}_dur${DUR}.txt
WAIT=0
TASKNUM=0

if [[ -z "${CASE}" || -z "${DUR}" ]];then
	echo "[Usage] run_test_case test_case_id duration"
	exit 1;
fi

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
echo "reset the scheduler"
setsched Linux
setsched GSN-FPCA
showsched
sudo cat /dev/litmus/log > ${LOG} &
echo "Now start test case ${CASE}"

#now at liblitmus folder
if [[ ${CASE} == 1 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 0 &
fi

if [[ ${CASE} == 2 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 16 &
fi

if [[ ${CASE} == 3 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 17 &
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
	./rtspin 50  150 $DUR -q 1 -C 1 -w ${WAIT} &
	./rtspin 150 200 $DUR -q 2 -C 1 -w ${WAIT} &
	./rtspin 150 300 $DUR -q 3 -C 1 -w ${WAIT} &
	./rtspin 150 400 $DUR -q 4 -C 1 -w ${WAIT} &
	./rtspin 150 600 $DUR -q 5 -C 1 -w ${WAIT} &
	./rtspin 150 600 $DUR -q 6 -C 1 -w ${WAIT} &
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
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
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
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
		TASKNUM=$(( ${TASKNUM} + 1 ))
	done
fi

# 200 tasks but only use 2 cores
if [[ ${CASE} == 10 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=200;i+=1));do
		period=$(( $(( ${i} * 100 )) ))
		cp=`expr ${i} % 16 + 1`
		exe=1
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
	done
fi

# 350 tasks but only use 3.5 cores
if [[ ${CASE} == 11 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=350;i+=1));do
		period=$(( $(( ${i} * 100 )) ))
		cp=`expr ${i} % 16 + 1`
		exe=1
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
	done
fi

# 390 tasks but only use 3.9 cores
if [[ ${CASE} == 12 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=390;i+=1));do
		period=$(( $(( ${i} * 100 )) ))
		cp=`expr ${i} % 16 + 1`
		exe=1
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
		#if [[ $(( i % 25 )) == 1 ]]; then
		#	sleep 1;
		#fi
	done
fi

# 200 tasks and overload system by using 5 cores
if [[ ${CASE} == 13 ]]; then
	#for((i=1; i<255;i+=1));do
	for((i=1; i<=500;i+=1));do
		period=$(( $(( ${i} * 100 )) ))
		cp=`expr ${i} % 16 + 1`
		exe=1
		echo "./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &"
		./rtspin ${exe} ${period} ${DUR} -q ${i} -C ${cp} -w ${WAIT} &
	done
fi

sleep 1
if [[ "${WAIT}" == "1" ]]; then
	./release_ts -f ${TASKNUM} &
fi
sleep ${DUR}
sleep 60
#killall cat
echo "[DONE] test=${CASE} dur=${DUR} log=${LOG}"
echo "---------------------------------"
