#!/bin/bash
# cat /dev/litmus/log > debug.txt &
DUR=10
cd ../
echo "I'm at "
pwd
sudo rm /root/debug.txt
sudo cat /dev/litmus/log > /root/debug.txt &
#now at liblitmus folder
./rtspin 100 1000 $DUR &
./rtspin 100 600 $DUR &

sleep $DUR
sleep 2
killall cat
echo "Remember to delete /root/debug.txt after you finish the traceing"
