#!/bin/bash
DEST=./data
sudo grep "rt: adding rtspin" /root/debug.txt > ${DEST}/debug-task-config.txt
sudo grep "preempted by" /root/debug.txt > ${DEST}/debug-task-preemption.txt
