#!/bin/bash
#set highest priority in FIFO

TMP=/tmp/find_pid.tmp

set_fifo(){
NAME=$1
if [[ "${NAME}" == "" ]]; then
	echo "!!set_fifo fails! proc name is ${NAME}"
	exit 1;
fi

rm -f ${TMP}
ps -a | grep ${NAME} > ${TMP}

i=1
while read first second nonimportant
do
	echo "pid=${first}"
	pids[$i]=${first}
	i=$(( ${i}+1 ))
	schedtool -F -p ${i} ${first}
	echo "schedtool -F -p ${i} ${first}"
done < ${TMP}
echo "pids are: ${pids[@]}"
}

if [[ $1 == "" ]];then
	echo "set_fifo.sh process_name"
	exit 1;
fi

set_fifo $1
