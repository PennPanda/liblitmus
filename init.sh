#!/bin/bash

SCHEDULER=$1
CACHE_INIT=0xffff

echo "Remove debug_log*"
rm -f debug_log*

echo 0 > /proc/sys/litmus/l1_prefetch
echo 0 > /proc/sys/litmus/l2_data_prefetch
echo 0 > /proc/sys/litmus/l2_prefetch_hint
echo 0 > /proc/sys/litmus/l2_double_linefill

if [[ "${SCHEDULER}" == "GSN-FP" ]]; then
	CACHE_INIT=0xffff
fi
if [[ "${SCHEDULER}" == "GSN-EDF" ]]; then
	CACHE_INIT=0xffff
fi
if [[ "${SCHEDULER}" == "GSN-FPCA" ]]; then
	CACHE_INIT=0x0
fi
if [[ "${SCHEDULER}" == "GSN-FPCA2" ]]; then
	CACHE_INIT=0x0
fi
if [[ "${SCHEDULER}" == "GSN-FPCANW" ]]; then
	CACHE_INIT=0x0
fi
if [[ "${SCHEDULER}" == "GSN-NPFPCA" ]]; then
	CACHE_INIT=0x0
fi

echo ${CACHE_INIT} > /proc/sys/litmus/C0_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C0_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C1_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C1_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C2_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C2_LB_way
echo ${CACHE_INIT} > /proc/sys/litmus/C3_LA_way
echo ${CACHE_INIT} > /proc/sys/litmus/C3_LB_way

./setsched ${SCHEDULER}
setsched ${SCHEDULER}
/home/ubuntu/liblitmus/setsched ${SCHEDULER}
