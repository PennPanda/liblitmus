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

for ((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=${num_tasks_step}));do
    output_oh_folder=${TRACEOH_ROOT}/numtasks${num_tasks}
    output_do_sched=${output_oh_folder}/xentrace_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-do_sched.csv
    output_cxt_switch=${output_oh_folder}/xentrace_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_switch.csv
    output_cxt_saved=${output_oh_folder}/xentrace_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_saved.csv
    if [[ -f ${output_do_sched} ]]; then
        echo "rm -f ${output_do_sched}"
        rm -f ${output_do_sched}
    fi
    if [[ -f ${output_cxt_switch} ]]; then
        echo "rm -f ${output_cxt_switch}"
        rm -f ${output_cxt_switch}
    fi
    if [[ -f ${output_cxt_saved} ]]; then
        echo "rm -f ${output_cxt_saved}"
        rm -f ${output_cxt_saved}
    fi

    for ((case=${case_min}; case<=${case_max}; case+=${case_step}));do
    for type in "${TYPES[@]}"
    do
        for alg in "${Algs[@]}"
        do
                input_oh_folder=${TRACEOH_ROOT}/numtasks${num_tasks}/xen
                input_do_sched=${input_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-do_sched.csv
                input_cxt_switch=${input_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_switch.csv
                input_cxt_saved=${input_oh_folder}/xentrace_test${case}_dur${DUR}_wait${WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}-cxt_saved.csv
                if [[ ${case} == ${case_min}  ]]; then
                    head -n 1 ${input_do_sched} >> ${output_do_sched}
                    head -n 1 ${input_cxt_switch} >> ${output_cxt_switch}
                    head -n 1 ${input_cxt_saved} >> ${output_cxt_saved}
                fi
                tail -n 1 ${input_do_sched} >> ${output_do_sched}
                tail -n 1 ${input_cxt_switch} >> ${output_cxt_switch}
                tail -n 1 ${input_cxt_saved} >> ${output_cxt_saved}
        done
    done
    done

done
