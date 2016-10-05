#!/bin/bash
source 00_env.sh
source 01_range.sh

declare -a Algs=( "GSN-EDF" )
#declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
declare -a TYPES=( "Uniform_Light" )
DUR=30 #seconds
WAIT=1 #release tasks at the same time?
#IS_CAT=1 #evaluate on CAT?
RTTASK=ca_spin_v3_oh_measurement
ROOT=/home/pennpanda/github/liblitmus-precise/scripts-oh-measurement/cat-paper
TRACEBIN_ROOT=${ROOT}/trace_bin
TRACECSV_ROOT=${ROOT}/trace_csv

declare -a EVENTS=( "CXS_START" "SCHED_START" "SCHED2_START" "RELEASE_START" "RELEASE_LATENCY" )

for ((case=${case_min}; case<=${case_max}; case+=${case_step}));do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for ((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=${num_tasks_step}));do
            xen_bin_folder="${TRACEBIN_ROOT}/numtasks${num_tasks}/xen"
            xen_csv_folder="${TRACECSV_ROOT}/numtasks${num_tasks}/xen"
            if [[ ! -d ${xen_csv_folder} ]]; then
                echo "mkdir -p ${xen_csv_folder}"
                mkdir -p ${xen_csv_folder}
            fi
            bin_file_all=${xen_bin_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}
            csv_file_all=${xen_csv_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-all.csv
            echo "Parse ${bin_file_all}. This may take a while... "
            if [[ -f ${csv_file_all} ]]; then
                echo "rm -f ${csv_file_all}"
                rm -f ${csv_file_all}
            fi
            cat ${bin_file_all} | xentrace_format ${FORMAT} >> ${csv_file_all} &
		done
	done
done
done
