#!/bin/bash
#Measure the trend of WCET over #CPs
cd ..
pwd

DEST=./data_wcet_vs_cp
mkdir ${DEST}

ARRAY_SIZE=640
LOOP_NUM=$1
if [[ ${LOOP_NUM} == "" ]];then
	LOOP_NUM=10
fi

for ((i=0;i<=16;i+=1));do
	FILENAME=${ARRAY_SIZE}_${LOOP_NUM}_${i}.data
	rm -f ${DEST}/${FILENAME}
	exe=$(( 5 * ${LOOP_NUM} ))
	period=$((${exe} + 10))
	./ca_spin -q 1 -C ${i} -S ${ARRAY_SIZE} -l ${LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} 10 > ${DEST}/${FILENAME}
	echo "./ca_spin -q 1 -C ${i} -S ${ARRAY_SIZE} -l ${LOOP_NUM} -r 1 -U 0 -f 1 ${exe} ${period} 10 > ${DEST}/${FILENAME}"
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
		#wcet_cur=${fifth}
		wcet_cur=$(( ${sixth} * 1000 ))
		echo "${wcet_cur}"
		if [[ ${wcet_cur} -ge ${WCET} ]];then
			WCET=${wcet_cur}
		fi
	done < ${input}

	return ${WCET}
}

SUMMARY_FILE=wcet_vs_cp_${ARRAY_SIZE}_${LOOP_NUM}.summary
rm ${DEST}/${SUMMARY_FILE}
for ((i=0; i<=16; i+=1));do
	FILENAME=${ARRAY_SIZE}_${LOOP_NUM}_${i}.data
	get_wcet ${DEST}/${FILENAME}
	wcet=${WCET}
	echo -e "${i}\t${wcet}" >> ${DEST}/${SUMMARY_FILE}
done
