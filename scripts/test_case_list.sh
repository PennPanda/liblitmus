#!/bin/bash

test_case(){
#now at liblitmus folder
if [[ ${CASE} == 2003 ]]; then
	./ca_spin ${WAIT} -q 1 -C 11 -S 704 -l 42 -r 1 -U 0 -f 0 200 200 ${DUR} &
fi
if [[ ${CASE} == 2004 ]]; then
	./ca_spin ${WAIT} -q 1 -C 11 -S 704 -l 42 -r 0 -U 0 -f 0 200 200 ${DUR} &
fi
#Prove we need cache-aware analysis
# exe = 2
if [[ ${CASE} == 1001 ]]; then
	./ca_spin ${WAIT} -q 1 -C 1 -S 64 -l 9 -r 1 -U 0 -f 0 200 200 ${DUR} &
fi

#exe = 30
if [[ ${CASE} == 1002 ]]; then
	./ca_spin ${WAIT} -q 1 -C 3 -S 192 -l 50 -r 1 -U 0 -f 0 200 200 ${DUR} &
fi

# exe = 75
if [[ ${CASE} == 1003 ]]; then
	./ca_spin ${WAIT} -q 1 -C 11 -S 704 -l 42 -r 1 -U 0 -f 0 200 200 ${DUR} &
fi

#overhead-free analysis is unsafe
if [[ ${CASE} == 1004 ]]; then
	./ca_spin ${WAIT} -q 1 -C 1  -S 64 -l 9 -r 1 -U 0 -f 0 2 10 ${DUR} &
	./ca_spin ${WAIT} -q 2 -C 1  -S 64 -l 9 -r 1 -U 0 -f 0 2 10 ${DUR} &
	./ca_spin ${WAIT} -q 3 -C 1  -S 64 -l 9 -r 1 -U 0 -f 0 2 10 ${DUR} &
	./ca_spin ${WAIT} -q 4 -C 3 -S 192 -l 50 -r 1 -U 0 -f 0 30 60 ${DUR} &
	./ca_spin ${WAIT} -q 5 -C 11 -S 704 -l 41 -r 1 -U 0 -f 0 78 100 ${DUR} &
fi
#overhead-aware analysis is safe
if [[ ${CASE} == 1005 ]]; then
	./ca_spin ${WAIT} -q 1 -C 1  -S 64 -l 9 -r 1 -U 0 -f 0 2 10 ${DUR} &
	./ca_spin ${WAIT} -q 2 -C 1  -S 64 -l 9 -r 1 -U 0 -f 0 2 10 ${DUR} &
	./ca_spin ${WAIT} -q 4 -C 3 -S 192 -l 50 -r 1 -U 0 -f 0 30 60 ${DUR} &
	./ca_spin ${WAIT} -q 5 -C 11 -S 704 -l 41 -r 1 -U 0 -f 0 78 100 ${DUR} &
fi
# performance test: WCET
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
	./ca_spin ${WAIT} -q 1 -C 8 -S 256 -l 100 -r 1 400 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
fi

if [[ ${CASE} == 105 ]]; then
	echo "./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &"
	./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
fi

if [[ ${CASE} == 106 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 98 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 9 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 10 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 11 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 400 1000 ${DUR} &
fi

if [[ ${CASE} == 107 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 98 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 11 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 400 1000 ${DUR} &
	./ca_spin ${WAIT} -q 2 -C 6 -S 384 -l 100 -r 1 400 1000 ${DUR} &
fi

if [[ ${CASE} == 108 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 109 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./cpu_spin ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 0 4900 5000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 110 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_spin ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 0 4900 5000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 111 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 98 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 11 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 6 -S 384 -l 100 -r 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 112 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 113 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./cpu_spin ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 0 995 1000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 114 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 1 995 1000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 1 900 1000 ${DUR} &
fi

if [[ ${CASE} == 115 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 0 900 1000 ${DUR} &
fi

if [[ ${CASE} == 116 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./cpu_spin ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 0 995 1000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 0 900 1000 ${DUR} &
fi

if [[ ${CASE} == 117 ]]; then
	#./ca_spin ${WAIT} -q 1 -C 6 -S 256 -l 100 -r 1 98 1000 ${DUR} &
	./ca_thrash ${WAIT} -q 11 -C 1 -S 1024 -l 1000 -r 1 995 1000 ${DUR} > /dev/null &
	./ca_spin ${WAIT} -q 1 -C 14 -S 768 -l 10 -r 1 -U 0 900 1000 ${DUR} &
fi

# performance test: deadline miss
if [[ ${CASE} == 201 ]]; then
	#./ca_spin ${WAIT} -q 4 -C 16 -S 992 -l 10 -r 1 -U 0 30 100 ${DUR} &
	#./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 10 -r 1 -U 0 58 70 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 20 -r 1 -U 0 -f 1 58 70 ${DUR} &
fi

if [[ ${CASE} == 202 ]]; then
	./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 10 -r 1 -U 0 6 30 ${DUR} &
	#./ca_spin ${WAIT} -q 2 -C 4 -S 224 -l 100 -r 1 -U 0 58 70 ${DUR} &
	#./ca_spin ${WAIT} -q 3 -C 4 -S 224 -l 100 -r 1 -U 0 58 70 ${DUR} &
	./ca_spin ${WAIT} -q 4 -C 16 -S 962 -l 10 -r 1 -U 0 30 300 ${DUR} &
	#./ca_thrash ${WAIT} -q 511 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
fi
# compare gFPca gFPcanw nongFPca
if [[ ${CASE} == 203 ]]; then
	./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 10 -r 1 -U 0 6 30 ${DUR} &
	./ca_spin ${WAIT} -q 2 -C 4 -S 216 -l 20 -r 1 -U 0 12 30 ${DUR} &
	./ca_spin ${WAIT} -q 4 -C 16 -S 962 -l 10 -r 1 -U 0 30 300 ${DUR} &
	./ca_spin ${WAIT} -q 10 -C 4 -S 216 -l 10 -r 1 -U 0 6 30 ${DUR} &
	#./ca_thrash ${WAIT} -q 511 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
fi
if [[ ${CASE} == 204 ]]; then
	./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 10 -r 1 -U 0 -e 6 91 ${DUR} &
	./ca_spin ${WAIT} -q 4 -C 16 -S 962 -l 10 -r 1 -U 0 -e 30 500 ${DUR} &
	./ca_spin ${WAIT} -q 10 -C 4 -S 216 -l 10 -r 1 -U 0 -e 6 100 ${DUR} &
	#./ca_thrash ${WAIT} -q 511 -C 1 -l 1000 -r 0 900 1000 ${DUR} &
fi
if [[ ${CASE} == 205 ]]; then
	#./ca_spin ${WAIT} -q 4 -C 16 -S 992 -l 10 -r 1 -U 0 30 100 ${DUR} &
	#./ca_spin ${WAIT} -q 1 -C 4 -S 216 -l 10 -r 1 -U 0 58 70 ${DUR} &
	./ca_spin ${WAIT} -q 1 -C 10 -S 640 -l 10 -r 1 -U 0 -f 1 200 200 ${DUR} &
fi
# functionality test
if [[ ${CASE} == 1 ]]; then
	./rtspin 100 200 $DUR -q 2 -C 0 &
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

}
