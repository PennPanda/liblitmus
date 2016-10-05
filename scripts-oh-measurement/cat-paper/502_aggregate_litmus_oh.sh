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

for alg in "${Algs[@]}"; do
for type in "${TYPES[@]}"; do
for event in "${EVENTS[@]}"; do
for ((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=${num_tasks_step}));do
    num_tasks_folder="${TRACEOH_ROOT}/numtasks${num_tasks}"
    if [[ ! -d ${num_tasks_folder} ]]; then
        echo "mkdir -p ${num_tasks_folder}"
        mkdir -p ${num_tasks_folder}
    fi
    analysis_stat_file=${num_tasks_folder}/trace_test${num_tasks_min}-${num_tasks_max}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id_min}-${dom_id_max}_env${ENV}-${event}.csv
    if [[ -f ${analysis_stat_file} ]]; then
        echo "rm -f ${analysis_stat_file}"
        rm -f ${analysis_stat_file}
    fi
    for ((case=${case_min}; case<=${case_max}; case+=${case_step}));do
        output_oh_folder=${TRACEOH_ROOT}/numtasks${num_tasks}/dom${dom_id_min}-${dom_id_max}
        output_analysis_file=${output_oh_folder}/trace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_dom${dom_id_min}-${dom_id_max}_env${ENV}-${event}.csv
        if [[ ${case} == ${case_min} ]]; then
            head -n 1 ${output_analysis_file} >> ${analysis_stat_file}
        fi
        tail -n 1 ${output_analysis_file} >> ${analysis_stat_file}
    done
done
done
done
done
