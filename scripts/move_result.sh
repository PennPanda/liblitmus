#!/bin/bash
ROOT=/home/ubuntu/mengxu/liblitmus
declare -a FOLDERS=( "trace_bin" "trace_csv" "trace_oh" )

for folder in "${FOLDERS[@]}"
do
scp -r ${ROOT}/${folder} hyonchoi@hylab:/home/hyonchoi/mengxu/rtas2016-workspace/trace/overhead-measurement/
echo "copy ${ROOT}/${folder} to hylab"
sleep 1
rm -rf ${ROOT}/${folder}/*
done
