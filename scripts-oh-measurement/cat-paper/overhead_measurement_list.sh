#!/bin/bash
FILE_RANDOM=/tmp/random
generate_workload(){
	type=$1
	num_tasks=$2
	rttask="./$3"
    WAIT=$4
    DUR=$5
    vanilla_file=$6
    cat_file=$7

    if [[ -f ${vanilla_file} ]]; then
        echo "rm -f ${vanilla_file}"
        rm -f ${vanilla_file}
    fi
    if [[ -f ${cat_file} ]]; then
        echo "rm -f ${cat_file}"
        rm -f ${cat_file}
    fi

    echo "#!/bin/bash" >> ${vanilla_file}
    echo "#!/bin/bash" >> ${cat_file}
	if [[ $3 == "" ]];then
		rttask=./ca_spin
	fi
	if [[ "${type}" == "Uniform_Light" ]];then
		util_min=1
		util_max=100
	fi
	if [[ "${type}" == "Uniform_Medium" ]];then
		util_min=100
		util_max=400
	fi
	if [[ "${type}" == "Uniform_Heavy" ]];then
		util_min=500
		util_max=900
	fi

	if [[ ${type} == "" || ${num_tasks} == "" ]];then
		echo "[ERROR] type(${type}) or num_tasks(${num_tasks}) is null"
		exit 1;
	fi

	for((i=1; i<=${num_tasks};i+=1));do
		shuf -i 350-850 -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		period=${rand}
		cp=`expr ${rand} % 19`
        cp=`expr ${cp} + 2`
		if [[ "${rttask}" == "./rtspin" || "${rttask}" == "rtspin" ]]; then
			cp=0
		fi
		shuf -i ${util_min}-${util_max} -n 1 > ${FILE_RANDOM}
		rand=`cat /tmp/random`
		exe=$(( $(( ${period} * ${rand} )) / 1000 + 1))
		wss=$(( ${cp} * 10 )) # we do not allocate too much memory to avoid out of memory
        generate_cp_setting ${cp} > /tmp/cp_setting
        CPs=`cat /tmp/cp_setting`
        echo "${rttask} ${exe} ${period} ${DUR} -D ${period} -s ${wss} ${WAIT} &" >> ${vanilla_file}
        echo "${rttask} ${exe} ${period} ${DUR} -D ${period} -C ${cp} -s ${wss} -P ${CPs} ${WAIT} &" >> ${cat_file}
		util=$(( ${util} +  $(( $(( ${exe} * 100 )) / ${period} )) ))
	done
	echo "echo \"release ${num_tasks} for ${type}\"" >> ${vanilla_file}
	echo "echo \"release ${num_tasks} for ${type}\"" >> ${cat_file}
}

