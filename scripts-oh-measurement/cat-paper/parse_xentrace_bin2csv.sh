#!/bin/bash
# Parse a xentrace bin file into a csv file
bin_file=$1
csv_file=$2
FORMAT=/home/panda/github/RT-Xen-Cache/tools/xentrace/formats

if [[ "${bin_file}" == ""  ||  "${csv_file}" == "" ]]; then
	echo "./script bin_file csv_file"
	exit 1;
fi

echo "Parse xentrace bin ${bin_file} into csv ${csv_file}"
echo "Check ${csv_file} filesize is increasing to make sure it is progressing"
echo "This may take a while..."
if [[ -f ${csv_file} ]]; then
	echo "rm -f ${csv_file}"
	rm -f ${csv_file}
fi

cat ${bin_file} | xentrace_format ${FORMAT} >> ${csv_file}
echo "cat ${bin_file} | xentrace_format ${FORMAT} >> ${csv_file}"
