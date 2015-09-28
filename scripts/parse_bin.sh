#!/bin/bash
INPUT=$1

DIR=`pwd`
TRACE_BIN=${DIR}/../trace_bin
TRACE_CSV=${DIR}/../trace_csv

if [[ "${INPUT}" == "" ]]; then
	echo "[Usage] ./parse_bin trace_prefix (st-trace_prefix-0.bin)"
	exit 1;
fi

st_job_stats ${TRACE_BIN}/st-${INPUT}-*.bin > ${TRACE_CSV}/st-${INPUT}.csv

echo "Result CSV file is at ${TRACE_CSV}/st-${INPUT}.csv"
