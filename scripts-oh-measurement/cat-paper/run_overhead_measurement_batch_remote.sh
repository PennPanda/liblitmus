#!/bin/bash
source 00_envs.sh

declare -a Algs=( "GSN-EDF" )
#declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
declare -a TYPES=( "Uniform_Light" )
num_tasks_min=50
num_tasks_step=50
num_tasks_max=100 #inclusive real exp uses 450
case_min=0
case_step=1
case_max=1 # inclusive real exp uses 9
dom_id_min=1
dom_id_step=1
dom_id_max=4
DUR=30 #seconds
WAIT=1 #release tasks at the same time?
RTTASK=ca_spin_v3_oh_measurement
ENV=cat

for ((case=${case_min}; case<=${case_max}; case+=${case_step}));do
for type in "${TYPES[@]}"
do
	for alg in "${Algs[@]}"
	do
		for ((num_tasks=${num_tasks_min}; num_tasks<=${num_tasks_max}; num_tasks+=${num_tasks_step}));do
            for ((dom_id=${dom_id_min}; dom_id<=${dom_id_max}; dom_id+=${dom_id_step})); do
                echo "ssh panda@dom${dom_id}:${SCRIPTS_ROOT}/run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${RTTASK} ${dom_id} ${ENV} &"
                ssh panda@dom${dom_id}:${SCRIPTS_ROOT}/run_overhead_measurement.sh ${case} ${DUR} ${WAIT} ${alg} ${type} ${num_tasks} ${RTTASK} ${dom_id} ${ENV} &
            done
            echo "Trace Xen sched events"
            xen_trace_folder=${XEN_TRACE_PATH}/numtasks${num_tasks}/xen
            if [[ ! -d ${xen_trace_folder }]]; then
                echo "mkdir -p ${xen_trace_folder}"
                mkdir -p ${xen_trace_folder}
            fi
            xen_trace_file=${xen_trace_folder}/xentrace_test${case}_dur${DUR}_wait${OPT_WAIT}_sched${alg}_type${type}_numtasks${num_tasks}_rt${RTTASK}_xen_env${ENV}
            # trace sched related events
            xentrace -D -e 0x0002f000 -T ${DUR} ${xen_trace_file}
            sleep ${DUR}
            sleep 20
		done
		#./move_result.sh
	done
done
done

echo "Overhead measurement for ${ENV} environment is done"
