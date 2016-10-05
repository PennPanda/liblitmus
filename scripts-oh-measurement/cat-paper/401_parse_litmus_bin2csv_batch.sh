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
            num_tasks_folder="${TASKSET_ROOT}/numtasks${num_tasks}"
            if [[ ! -d ${num_tasks_folder} ]]; then
                echo "mkdir -p ${num_tasks_folder}"
                mkdir -p ${num_tasks_folder}
            fi
            # Parse domU bin data
            for ((dom_id=${dom_id_min}; dom_id<=${dom_id_max}; dom_id+=${dom_id_step}));do
                dom_id_folder="${num_tasks_folder}/dom${dom_id}"
                if [[ ! -d ${dom_id_folder} ]]; then
                    echo "mkdir -p ${dom_id_folder}"
                    mkdir -p ${dom_id_folder}
                fi
                bin_folder=${TRACEBIN_ROOT}/numtasks${num_tasks}/dom${dom_id}
                csv_folder=${TRACECSV_ROOT}/numtasks${num_tasks}/dom${dom_id}
                if [[ ! -d ${bin_folder} ]]; then
                    echo "mkdir -p ${bin_folder}"
                    mkdir -p ${bin_folder}
                fi
                if [[ ! -d ${csv_folder} ]]; then
                    echo "mkdir -p ${csv_folder}"
                    mkdir -p ${csv_folder}
                fi
                bin_file_all=${bin_folder}/oh-trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id}_env${ENV}-all.bin
                if [[ ! -f ${bin_file_all} ]]; then
                    echo "ERROR: ${bin_file_all} not exist..."
                    exit 1;
                fi
                for event in "${EVENTS[@]}"
                do
                    csv_file_event=${csv_folder}/trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id}_env${ENV}-${event}.csv
                    echo "Parse Overhead Event: ${event}"
                    echo "ft2csv ${event} ${bin_file_all} > ${csv_file_event}"
                    ft2csv ${event} ${bin_file_all} > ${csv_file_event}
                done
                echo "Parse bin ${bin_file_all} to csv ${csv_file_event}..."
            done
		done
	done
done
done
