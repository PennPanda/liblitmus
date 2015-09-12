#!/bin/bash
# cat /dev/litmus/log > debug.txt &
DUR=60
cd ../
echo "I'm at "
pwd
sudo rm /root/debug.txt
sudo cat /dev/litmus/log > /root/debug.txt &
#now at liblitmus folder
#./rtspin 100 101 $DUR -q 1 &
./rtspin 10 200 $DUR -q 2 -C 14 &
#./rtspin 100 301 $DUR -q 3 -C 4 &
#./rtspin 100 401 $DUR -q 4 -C 4 &
#./rtspin 100 501 $DUR -q 5 -C 4 &
#./rtspin 100 601 $DUR -q 6 -C 4 &
#./rtspin 100 701 $DUR -q 7 -C 5 &
#./rtspin 100 801 $DUR -q 8 -C 4 &
./rtspin 850 901 $DUR -q 9 -C 4 &
./rtspin 850 902 $DUR -q 10 -C 4 &
./rtspin 850 903 $DUR -q 11 -C 4 &
./rtspin 850 904 $DUR -q 12 -C 4 &

sleep $DUR
sleep 2
killall cat
echo "Remember to delete /root/debug.txt after you finish the traceing"
