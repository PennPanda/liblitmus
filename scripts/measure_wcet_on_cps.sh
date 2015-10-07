#!/bin/bash
#Measure the trend of WCET over #CPs
cd ..
pwd

DEST=./data_wcet_vs_cp
mkdir ${DEST}

ARRAY_SIZE=$1
LOOP_NUM=$2
HOT_ARRAY_SIZE=$3
HOT_LOOP_NUM=$4
TASK=$5
DUR=10
if [[ ${LOOP_NUM} == "" || ${HOT_LOOP_NUM} == "" || ${TASK} == "" ]];then
	LOOP_NUM=10
	echo "[input] array_size loop_num hot_array_size hot_loop_num task"
	exit 1;
fi

for ((i=0;i<=16;i+=1));do
	FILENAME=${TASK}_${ARRAY_SIZE}_${LOOP_NUM}_${HOT_ARRAY_SIZE}_${HOT_LOOP_NUM}_${i}.data
	rm -f ${DEST}/${FILENAME}
	#exe=$(( 5 * ${LOOP_NUM} ))
	#period=$((${exe} + 10))
	exe=2000
	period=2010
	./${TASK} -q 1 -C ${i} -s ${ARRAY_SIZE} -l ${LOOP_NUM} -S ${HOT_ARRAY_SIZE} -L ${HOT_LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} ${DUR} > ${DEST}/${FILENAME}
	echo "./${TASK} -q 1 -C ${i} -s ${ARRAY_SIZE} -l ${LOOP_NUM} -S ${HOT_ARRAY_SIZE} -L ${HOT_LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} ${DUR} > ${DEST}/${FILENAME}"
done

get_wcet(){
	input=$1
	LINENUM=0
	WCET=0
	while read first  second third fourth fifth sixth nonimportant
	do
		LINENUM=$(( ${LINENUM}+1 ));
		if [[ ${LINENUM} -le 6 ]]; then
			continue;
		fi
		wcet_cur=${fifth}
		#wcet_cur=$(( ${sixth} * 1000 ))
		#echo "${wcet_cur}"
		if [[ ${wcet_cur} -ge ${WCET} ]];then
			WCET=${wcet_cur}
		fi
	done < ${input}

	return ${WCET}
}

SUMMARY_FILE=wcet_vs_cp_${TASK}_${ARRAY_SIZE}_${LOOP_NUM}_${HOT_ARRAY_SIZE}_${HOT_LOOP_NUM}.summary
rm ${DEST}/${SUMMARY_FILE}
for ((i=0; i<=16; i+=1));do
	FILENAME=${TASK}_${ARRAY_SIZE}_${LOOP_NUM}_${HOT_ARRAY_SIZE}_${HOT_LOOP_NUM}_${i}.data
	get_wcet ${DEST}/${FILENAME}
	wcet=${WCET}
	echo -e "${i}\t${wcet}" >> ${DEST}/${SUMMARY_FILE}
done
