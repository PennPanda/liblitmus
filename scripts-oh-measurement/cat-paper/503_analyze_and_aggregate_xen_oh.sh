#!/bin/bash
source 00_env.sh
source 01_range.sh

NUM_PARALLELS=8

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
            # We run the processing in parallel but only allow NUM_PARALLELS python at the same time
            for((; 1;));do
                num_pythons=`ps -a | grep python |wc -l`
                if [[ ${num_pythons} < ${NUM_PARALLELS} ]]; then
                    break;
                else
                    sleep 30
                fi
            done
            csv_folder=${TRACECSV_ROOT}/numtasks${num_tasks}/xen
            input_csv_file=${csv_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-all.csv
            output_oh_folder=${TRACEOH_ROOT}/numtasks${num_tasks}/xen
            if [[ ! -d ${output_oh_folder} ]]; then
                echo "mkdir -p ${output_oh_folder}"
                mkdir -p ${output_oh_folder}
            fi
            output_do_sched=${output_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-do_sched.csv
            output_cxt_switch=${output_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_switch.csv
            output_cxt_saved=${output_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_saved.csv
            if [[ -f ${output_do_sched} ]]; then
                rm -f ${output_do_sched}
            fi
            if [[ -f ${output_cxt_switch} ]]; then
                rm -f ${output_cxt_switch}
            fi
            if [[ -f ${output_cxt_saved} ]]; then
                rm -f ${output_cxt_saved}
            fi
            echo "python ./analyze_xentrace_csv2result_v2.py ${input_csv_file} ${output_do_sched} ${output_cxt_switch} ${output_cxt_saved} &"
            python ./analyze_xentrace_csv2result_v2.py ${input_csv_file} ${output_do_sched} ${output_cxt_switch} ${output_cxt_saved} &
	    done
	done
done
done
done
