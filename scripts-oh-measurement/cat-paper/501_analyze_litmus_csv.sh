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
TRACEOH_ROOT=${ROOT}/trace_oh

declare -a EVENTS=( "CXS_START" "SCHED_START" "SCHED2_START" "RELEASE_START" "RELEASE_LATENCY" )

for event in "${EVENTS[@]}"
do
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
            # Generate input parameters
            input_csv_files=""
            for ((dom_id=${dom_id_min}; dom_id<=${dom_id_max}; dom_id+=${dom_id_step}));do
                csv_folder=${TRACECSV_ROOT}/numtasks${num_tasks}/dom${dom_id}
                csv_file_event=${csv_folder}/trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id}_env${ENV}-${event}.csv
                input_csv_files="${input_csv_files} ${csv_file_event}"
            done
            output_oh_folder=${TRACEOH_ROOT}/numtasks${num_tasks}/dom${dom_id_min}-${dom_id_max}
            if [[ ! -d ${output_oh_folder} ]]; then
                echo "mkdir -p ${output_oh_folder}"
                mkdir -p ${output_oh_folder}
            fi
            output_analysis_file=${output_oh_folder}/trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id_min}-${dom_id_max}_env${ENV}-${event}.csv
            python analyze_litmustrace_csv2result.py ${num_doms} ${input_csv_files} ${output_analysis_file}
		done
	done
done
done
done
