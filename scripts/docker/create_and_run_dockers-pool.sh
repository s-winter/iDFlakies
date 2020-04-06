#!/bin/bash

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - The script to run (Optional)"
    exit
fi

date

projfile=$1
rounds=$2
timeout=$3
script="$4"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# For each project,sha, make a Docker image for it
for line in $(cat ${projfile}); do
    slug=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-2 | rev)
    sha=$(echo ${line} | cut -d',' -f2)
    modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')
    image=detector-${modifiedslug}:latest
    # Run the Docker image if it exists
    docker inspect ${image} > /dev/null 2>&1
    if [ $? == 1 ]
    then
        echo "${image} NOT BUILT PROPERLY, LIKELY TESTS FAILED"
    else
	if [ -p SCRIPTEND_${image} -o -p DATAREAD_${image} ]
	then
	    echo "Named pipes exist. Previous run has likely terminated abnormally! Removing now to continue..."
	    rm SCRIPTEND_${image}
	    rm DATAREAD_${image}
	fi
	mkfifo --mode=777 SCRIPTEND_${image}
	mkfifo --mode=777 DATAREAD_${image}
	# kill any running docker container for the same image before running this one
	containerHash=$(docker ps | grep ${image} | tr -s ' ' | cut -d' ' -f1)
	[ "${containerHash}" == "" ] || docker kill ${containerHash}
	#export SYSFSRESULTS_DIR_${modifiedlug}=$SCRIPT_DIR/sysfsresults/$modifiedslug
	export SYSFSRESULTS_DIR=$SCRIPT_DIR/sysfsresults/$modifiedslug
	./wait_for_docker_completion.sh ${image} ${modifiedslug} &
	echo "Running with ${THROTTLING_CPUSET} ${THROTTLING_CPUS} ${THROTTLING_MEM} ${THROTTLING_SWAP} ${THROTTLING_OOM} ${THROTTLING_READ_BPS} ${THROTTLING_WRITE_BPS} ${THROTTLING_READ_IOPS} ${THROTTLING_WRITE_IOPS}"
        /usr/bin/time -v docker run -t --rm ${THROTTLING_CPUSET} ${THROTTLING_CPUS} ${THROTTLING_MEM} ${THROTTLING_SWAP} ${THROTTLING_OOM} ${THROTTLING_READ_BPS} ${THROTTLING_WRITE_BPS} ${THROTTLING_READ_IOPS} ${THROTTLING_WRITE_IOPS} -v ${SCRIPT_DIR}:/Scratch ${image} /bin/bash -xc "/Scratch/run_experiment.sh ${slug} ${rounds} ${timeout} ${image} ${script}" # |ts "[ %F %H:%M:%.S ]"
    fi
done
