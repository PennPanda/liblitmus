#!/bin/bash
#Measure the trend of WCET over #CPs
cd ..
pwd

DEST=./data_wcet_vs_cp
mkdir ${DEST}

NUM_CP=19
ARRAY_SIZE=10240
LOOP_NUM=$1

POLLUTE_TYPE_NOPOLLUTE=0
POLLUTE_TYPE_CAT=1
POLLUTE_TYPE_NOCAT=2
POLLUTE=${POLLUTE_TYPE_CAT}

if [[ ${LOOP_NUM} == "" ]];then
	LOOP_NUM=10
fi

run_experiment()
{
for ((i=2;i<=${NUM_CP};i+=1));do
	FILENAME=${ARRAY_SIZE}_${LOOP_NUM}_${i}_${POLLUTE}.data
	rm -f ${DEST}/${FILENAME}

	if [[ ${POLLUTE} == ${POLLUTE_TYPE_CAT} ]]; then
		./ca_spin -q 1 -p 1 -M 0xC -S 20480 -l 10 -r 1 -U 0 -f 0 1000 1000 15 &
		echo "pollute task is released for 15 seconds"
	fi
	if [[ ${POLLUTE} == ${POLLUTE_TYPE_NOCAT} ]]; then
		./ca_spin -q 1 -p 1 -M 0xfffff -S 20480 -l 10 -r 1 -U 0 -f 0 1000 1000 15 &
		echo "pollute task is released for 15 seconds"
	fi

	cp_set=0;
	for((j=0; j<i; j+=1)); do
		cp_set=$(( ${cp_set} | $(( 1 << ${j})) ))
	done
	echo "num_cps=$i uses cp set:"
	printf "0x%04x " ${cp_set}
	echo " "
	exe=$(( 5 * ${LOOP_NUM} ))
	period=$((${exe} + 10))
	./ca_spin -q 1 -p 1 -M ${cp_set} -S ${ARRAY_SIZE} -l ${LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} 10 > ${DEST}/${FILENAME}
	echo "./ca_spin -q 1 -p 1 -C ${i} -M ${cp_set} -S ${ARRAY_SIZE} -l ${LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} 10 > ${DEST}/${FILENAME}"
done
}

get_wcet(){
	input=$1
	LINENUM=0
	WCET=0
	while read first  second third fourth fifth sixth nonimportant
	do
		LINENUM=$(( ${LINENUM}+1 ));
		if [[ ${LINENUM} -le 6 || ${sixth} == "" ]]; then
			continue;
		fi
		#echo "${sixth}"
		wcet_cur=${sixth}
		#wcet_cur=`echo "${sixth} * 1000" | bc`
		echo "${wcet_cur}"
		if [[ ${wcet_cur} -ge ${WCET} ]];then
			WCET=${wcet_cur}
		fi
	done < ${input}

	return ${WCET}
}

run_experiment

SUMMARY_FILE=wcet_vs_cp_${ARRAY_SIZE}_${LOOP_NUM}_${POLLUTE}.summary
rm ${DEST}/${SUMMARY_FILE}
for ((i=2; i<=${NUM_CP}; i+=1));do
	FILENAME=${ARRAY_SIZE}_${LOOP_NUM}_${i}_${POLLUTE}.data
	get_wcet ${DEST}/${FILENAME}
	wcet=${WCET}
	echo -e "${i}\t${wcet}" >> ${DEST}/${SUMMARY_FILE}
done
