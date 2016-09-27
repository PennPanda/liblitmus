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

for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for ((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=${num_tasks_step}));do
            num_tasks_folder="${TRACEBIN_ROOT}/numtasks${num_tasks}"
            if [[ ! -d ${num_tasks_folder} ]]; then
                echo "mkdir -p ${num_tasks_folder}"
                echo "Something is wrong. The folder should have exit."
                mkdir -p ${num_tasks_folder}
            fi
            for ((dom_id=${dom_id_min}; dom_id<=${dom_id_max}; dom_id+=${dom_id_step}));do
                echo "scp -r root@dom${dom_id}:${num_tasks_folder}/dom${dom_id} ${num_tasks_folder}/"
                scp -r root@dom${dom_id}:${num_tasks_folder}/dom${dom_id} ${num_tasks_folder}/
            done
		done
	done
done
