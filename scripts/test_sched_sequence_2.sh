#!/bin/bash
# cat /dev/litmus/log > debug.txt &
DUR=100
cd ../
echo "I'm at "
pwd
sudo rm /root/debug.txt
sudo cat /dev/litmus/log > /root/debug.txt &
#now at liblitmus folder
./rtspin 100 101 $DUR -q 1 &
./rtspin 100 200 $DUR -q 2 &
./rtspin 100 301 $DUR -q 3 &
./rtspin 100 401 $DUR -q 4 &
./rtspin 100 501 $DUR -q 5 &
./rtspin 100 601 $DUR -q 6 &
./rtspin 100 701 $DUR -q 7 &
./rtspin 100 801 $DUR -q 8 &
./rtspin 100 901 $DUR -q 9 &

sleep $DUR
sleep 2
killall cat
echo "Remember to delete /root/debug.txt after you finish the traceing"
