#!/bin/bash
generate_workload(){
	type=$1
	num_tasks=$2
	rttask="./$3"
	if [[ $3 == "" ]];then
		rttask=./ca_spin
	fi
	if [[ "${type}" == "Uniform_Light" ]];then
		util_min=1
		util_max=100
	fi
	if [[ "${type}" == "Uniform_Medium" ]];then
		util_min=100
		util_max=400
	fi
	if [[ "${type}" == "Uniform_Heavy" ]];then
		util_min=500
		util_max=900
	fi

	if [[ ${type} == "" || ${num_tasks} == "" ]];then
		echo "[ERROR] type(${type}) or num_tasks(${num_tasks}) is null"
		exit 1;
	fi

	for((i=1; i<=${num_tasks};i+=1));do
		shuf -i 350-850 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 16`
		if [[ "${rttask}" == "./rtspin" || "${rttask}" == "rtspin" ]]; then
			cp=0
		fi
		shuf -i ${util_min}-${util_max} -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 1000 ))
		wss=$(( ${cp} * 64 ))
		echo "${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} -S ${wss} ${WAIT} &"
		${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
	done
	echo "release ${num_tasks} for ${type}"
}

overhead_measurement_case(){
#now at liblitmus folder
if [[ ${CASE} == 1 ]]; then
	./rtspin 100 200 $DUR -q 2 
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
		echo "${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
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
		echo "${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
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
		echo "${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &"
		${rttask} ${exe} ${period} ${DUR} -q ${i} -C ${cp} ${WAIT} &
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
		if [[ ${util} -ge 350 ]]; then
			break;
		fi
	done
fi
}
