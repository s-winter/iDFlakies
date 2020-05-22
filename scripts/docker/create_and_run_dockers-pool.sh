#!/bin/bash

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - The script to run (Optional)"
    echo "arg5 - roundsIndex"
    exit
fi

date

projfile=$1
rounds=$2
timeout=$3
script="$4"
roundsIndex=$5

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# For each project,sha, make a Docker image for it
for line in $(cat ${projfile}); do
    slug=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-2 | rev)
    sha=$(echo ${line} | cut -d',' -f2)
    testName=$(echo $line | cut -d, -f3)
    modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')
    image=detector-${modifiedslug}:latest
    # Run the Docker image if it exists
    docker inspect ${image} > /dev/null 2>&1
    if [ $? == 1 ]
    then
        echo "${image} NOT BUILT PROPERLY, LIKELY TESTS FAILED"
    else
	export runId="${modifiedslug}_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"
	mkfifo --mode=777 SCRIPTEND_${runId}
	mkfifo --mode=777 DATAREAD_${runId}
	# kill any running docker container for the same image before running this one
	# containerHash=$(docker ps | grep ${image} | tr -s ' ' | cut -d' ' -f1)
	# [ "${containerHash}" == "" ] || docker kill ${containerHash}
	#export SYSFSRESULTS_DIR_${modifiedlug}=$SCRIPT_DIR/sysfsresults/$modifiedslug
	export SYSFSRESULTS_DIR="/Scratch/sysfsresults/${runId}"
	./wait_for_docker_completion.sh ${image} ${modifiedslug} &
        /usr/bin/time -v docker run -t --rm --name "${runId}" -v ${SCRIPT_DIR}:/Scratch ${image} /bin/bash -xc "/Scratch/run_experiment.sh ${slug} ${testName} ${rounds} ${timeout} ${image} ${script} ${roundsIndex} ${runId} " # |ts "[ %F %H:%M:%.S ]"
    fi
done
