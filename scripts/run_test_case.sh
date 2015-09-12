#!/bin/bash
# cat /dev/litmus/log > debug.txt &
CASE=$1
DUR=$2
LOG=/root/debug_test${CASE}_dur${DUR}.txt

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

sleep ${DUR}
sleep 2
killall cat
echo "[DONE] test=${CASE} dur=${DUR} log=${LOG}"
echo "---------------------------------"
