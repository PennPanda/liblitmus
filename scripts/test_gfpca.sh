source test_case_list.sh

cd ../

APP=ca_spin_v2

test1()
{
echo "---test_case 1 start---"
CASE=1
WAIT=1
DUR=60
./ca_spin_v2 10 100 60 -D 100 -q 1 -C 8 &
echo "---test_case 1 finish---"
}

test2()
{
echo "---test_case 2 start---"
CASE=1
WAIT=1
DUR=60
./ca_spin_v2 10 100 30 -D 100 -q 1 -C 8 &
./ca_spin_v2 10 101 30 -D 100 -q 1 -C 8 &
./ca_spin_v2 10 101 30 -D 100 -q 1 -C 8 &
echo "---test_case 2 finish---"
}

test3()
{
echo "---test_case 3 start---"
CASE=1
WAIT=1
DUR=30
./ca_spin_v2 10 100 ${DUR} -D 100 -q 1 -C 4 ${WAIT} &
./ca_spin_v2 10 101 ${DUR} -D 100 -q 1 -C 3 ${WAIT} &
./ca_spin_v2 10 101 ${DUR} -D 100 -q 1 -C 10 ${WAIT} &
./ca_spin_v2 10 102 ${DUR} -D 100 -q 1 -C 5 ${WAIT} &
echo "---test_case 3 finish---"
}
# echo "Stop here"
# exit 0
test100()
{
echo "---test_case 100 start---"
CASE=100
WAIT=1
DUR=10
TASKNUM=0;
for((i=1; i<20;i+=1));do
    period=$(( 500 + $(( ${i}  )) ))
    cp=`expr ${i} % 14 + 2`
    #exe=10, 11 #2 rtspins left
    #exe=5 or 1 #no rtspin left
    exe=10
    cp_init=0xf
    echo "./${APP} ${exe} ${period} ${DUR} -D ${period} -q ${i} -C ${cp} ${WAIT} &"
    ./${APP} ${exe} ${period} ${DUR} -D ${period} -q ${i} -C ${cp} ${WAIT} &
    #if [[ $(( i % 25 )) == 1 ]]; then
    #	sleep 1;
    #fi
    TASKNUM=$(( ${TASKNUM} + 1 ))
done
}

test101()
{
echo "---test_case 100 start---"
CASE=101
WAIT=1
DUR=10
TASKNUM=0;
for((i=1; i<200;i+=1));do
    period=$(( 500 + $(( ${i}  )) ))
    cp=`expr ${i} % 14 + 2`
    #exe=10, 11 #2 rtspins left
    #exe=5 or 1 #no rtspin left
    exe=10
    cp_init=0xf
    echo "./${APP} ${exe} ${period} ${DUR} -D ${period} -q ${i} -C ${cp} ${WAIT} &"
    ./${APP} ${exe} ${period} ${DUR} -D ${period} -q ${i} -C ${cp} ${WAIT} &
    #if [[ $(( i % 25 )) == 1 ]]; then
    #	sleep 1;
    #fi
    TASKNUM=$(( ${TASKNUM} + 1 ))
done
echo "---test_case 100 finish---"
}

test101
