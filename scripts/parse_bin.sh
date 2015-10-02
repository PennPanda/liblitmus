#!/bin/bash
INPUT=$1

DIR=`pwd`
TRACE_BIN=${DIR}/../trace_bin
TRACE_CSV=${DIR}/../trace_csv
TRACE_OH=${DIR}/../trace_oh

mkdir ${TRACE_OH}

if [[ "${INPUT}" == "" ]]; then
	echo "[Usage] ./parse_bin trace_prefix (oh-trace_prefix-0.bin)"
	exit 1;
fi

st_job_stats ${TRACE_BIN}/oh-${INPUT}-*.bin > ${TRACE_CSV}/oh-${INPUT}.csv

cat ${TRACE_BIN}/oh-${INPUT}-?.bin > ${TRACE_BIN}/oh-${INPUT}-all.bin
#parse all events
declare -a EVENTS=( "CXS_START" "SCHED_START" "SCHED2_START" "RELEASE_START" )
for event in "${EVENTS[@]}"
do
	echo "Parse Overhead Event: ${event}"
	ft2csv ${event} ${TRACE_BIN}/oh-${INPUT}-all.bin > ${TRACE_OH}/oh-${INPUT}-${event}.oh
	awk '$3>x{x=$3};END{print x}' ${TRACE_OH}/oh-${INPUT}-${event}.oh > ${TRACE_OH}/oh-${INPUT}-${event}-max.oh
	echo "${event} max:"
	cat ${TRACE_OH}/oh-${INPUT}-${event}-max.oh
done

echo "Result CSV file is at ${TRACE_CSV}/st-${INPUT}.csv"
