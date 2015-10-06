#!/bin/bash
Alg=$1
rttask=$2
DUR=$3
./init.sh $Alg

#ftcat -v -c /dev/litmus/ft_msg_trace0
ftcat /dev/litmus/ft_msg_trace0 SEND_RESCHED_START SEND_RESCHED_END > msg0.bin &
ftcat /dev/litmus/ft_msg_trace1 SEND_RESCHED_START SEND_RESCHED_END > msg1.bin &
ftcat /dev/litmus/ft_msg_trace2 SEND_RESCHED_START SEND_RESCHED_END > msg2.bin &
ftcat /dev/litmus/ft_msg_trace3 SEND_RESCHED_START SEND_RESCHED_END > msg3.bin &

ftcat /dev/litmus/ft_cpu_trace0 CXS_START CXS_END SCHED_START SCHED_END SCHED2_START SCHED2_END > cpu0.bin &
ftcat /dev/litmus/ft_cpu_trace1 CXS_START CXS_END SCHED_START SCHED_END SCHED2_START SCHED2_END > cpu1.bin &
ftcat /dev/litmus/ft_cpu_trace2 CXS_START CXS_END SCHED_START SCHED_END SCHED2_START SCHED2_END > cpu2.bin &
ftcat /dev/litmus/ft_cpu_trace3 CXS_START CXS_END SCHED_START SCHED_END SCHED2_START SCHED2_END > cpu3.bin &

for((i=i;i<20; i+=1));do
   ${rttask} 2 100 ${DUR} -q ${i} &
done

sleep ${DUR}
killall -2 ftcat

cat msg*.bin > msg-all.bin
cat cpu*.bin > cpu-all.bin

ft2csv SEND_RESCHED msg-all.bin > msg-all.csv
./get_max_value.sh msg-all.csv

echo "TODO: parse msg[0-3].bin and check max latency"
