#!/bin/bash
FILE=$1

TRACE_CSV=../trace_csv
TRACE_BIN=../trace_bin

if [[ "${FILE}" == "" ]];then
	echo "[Usage] ./find_ddl_miss csv_file_prefix"
	exit 1;
fi

echo "[find_ddl_miss] Parse ${TRACE_CSV}/st-${FILE}.csv"
awk '$6 >= 1 { print $0}' ${TRACE_CSV}/st-${FILE}.csv > ${TRACE_CSV}/st-${FILE}.ddlmiss
cat ${TRACE_CSV}/st-${FILE}.ddlmiss
