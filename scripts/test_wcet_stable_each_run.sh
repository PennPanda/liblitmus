#!/bin/bash
mkdir ../test_wcet_stable
TEST_CASE=2004

for ((i=1;i<10;i+=1));do
	echo $i
	./run_test_case.sh ${TEST_CASE} 20 1 GSN-FPCA
	FILE=st-trace_test${TEST_CASE}_dur20_wait1_schedGSN-FPCA
	cp ../trace_csv/${FILE}.csv ../test_wcet_stable/${FILE}_${i}.csv
done

