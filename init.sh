#!/bin/bash

SCHEDULER=$1

./setsched $SCHEDULER

echo 0 > /proc/sys/litmus/l1_prefetch
echo 0 > /proc/sys/litmus/l2_data_prefetch
echo 0 > /proc/sys/litmus/l2_prefetch_hint
echo 0 > /proc/sys/litmus/l2_double_linefill

echo 0xffff > /proc/sys/litmus/C0_LA_way
echo 0xffff > /proc/sys/litmus/C0_LB_way
echo 0xffff > /proc/sys/litmus/C1_LA_way
echo 0xffff > /proc/sys/litmus/C1_LB_way
echo 0xffff > /proc/sys/litmus/C2_LA_way
echo 0xffff > /proc/sys/litmus/C2_LB_way
echo 0xffff > /proc/sys/litmus/C3_LA_way
echo 0xffff > /proc/sys/litmus/C3_LB_way

