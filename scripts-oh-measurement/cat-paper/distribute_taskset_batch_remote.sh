#!/bin/bash
source 00_env.sh

chmod a+x -r ${TASKSET_ROOT}/
echo "chmod a+x -r ${TASKSET_ROOT}/"
for ((dom_id=${dom_id_min}; dom_id<=${dom_id_max}; dom_id+=${dom_id_step})); do
    echo "ssh root@dom${dom_id} \"mkdir -p ${TASKSET_ROOT}\""
    ssh root@dom${dom_id} "mkdir -p ${TASKSET_ROOT}"
    echo "ssh root@dom${dom_id} \"mkdir -p ${ST_TRACE_PATH}\""
    ssh root@dom${dom_id} "mkdir -p ${ST_TRACE_PATH}"
    echo "scp -r ${TASKSET_ROOT}/* root@dom${dom_id}:${TASKSET_ROOT}/"
    scp -r ${TASKSET_ROOT}/* root@dom${dom_id}:${TASKSET_ROOT}/
    echo "scp -r ${SCRIPTS_ROOT}/*.sh root@dom${dom_id}:${SCRIPTS_ROOT}/"
    scp -r ${SCRIPTS_ROOT}/*.sh root@dom${dom_id}:${SCRIPTS_ROOT}/
    echo "scp -r ${SCRIPTS_ROOT}/*.py root@dom${dom_id}:${SCRIPTS_ROOT}/"
    scp -r ${SCRIPTS_ROOT}/*.py root@dom${dom_id}:${SCRIPTS_ROOT}/
    echo "ssh root@dom${dom_id} \"chmod a+x -R ${TASKSET_ROOT}\""
    ssh root@dom${dom_id} "chmod a+x -R ${TASKSET_ROOT}"
done

