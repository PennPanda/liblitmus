#!/bin/bash

LIBLITMUS_ROOT=/home/pennpanda/github/liblitmus-precise
SCRIPTS_ROOT=${LIBLITMUS_ROOT}/scripts-oh-measurement/cat-paper
TRACEDATA_ROOT=${SCRIPTS_ROOT}
ST_TRACE_PATH=${TRACEDATA_ROOT}/trace_bin
XEN_TRACE_PATH=${TRACEDATA_ROOT}/trace_bin
TASKSET_ROOT=${SCRIPTS_ROOT}/tasksets_autogenerated
export PATH=${PATH}:${SCRIPTS_ROOT}:.
FORMAT=/home/panda/github/RT-Xen-Cache/tools/xentrace/formats

# run_overhead_measurement_batch_remote.sh
declare -a Algs=( "GSN-EDF" )
#declare -a TYPES=( "Uniform_Light" "Uniform_Medium" "Uniform_Heavy" )
declare -a TYPES=( "Uniform_Light" )
num_tasks_min=50
num_tasks_step=400
num_tasks_max=450 #inclusive real exp uses 450
case_min=0
case_step=1
case_max=9 # inclusive real exp uses 9
dom_id_min=1
dom_id_step=1
dom_id_max=4
NUM_CPUS=4
DUR=30 #seconds
WAIT=1 #release tasks at the same time?
RTTASK=ca_spin_v3_oh_measurement
ENV=cat

