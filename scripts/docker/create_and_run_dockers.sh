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

[ -x $SCRIPT_DIR/throttling.sh ] || { echo "No throttling definitions found"; exit 1; }
source $SCRIPT_DIR/throttling.sh

echo "*******************IDFLAKIES DEBUG************************"
echo "Making base image"
date

# Create base Docker image if does not exist
docker inspect detectorbase:latest > /dev/null 2>&1
if  [ $?  == 1 ]; then
    docker build -t detectorbase:latest - < baseDockerfile
fi

echo "*******************IDFLAKIES DEBUG************************"
echo "Making tooling image"
date

# Create tooling Docker image if does not exist
docker inspect toolingdetectorbase:latest > /dev/null 2>&1
if  [ $?  == 1 ]; then
    docker build -t toolingdetectorbase:latest - < toolingDockerfile
fi

# For each project,sha, make a Docker image for it
for line in $(cat ${projfile}); do
    # Create the corresponding Dockerfile
    slug=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-2 | rev)
    sha=$(echo ${line} | cut -d',' -f2)
    ./create_dockerfile.sh ${slug} ${sha}

    # Build the Docker image if does not exist
    modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')
    image=detector-${modifiedslug}:latest
    docker inspect ${image} > /dev/null 2>&1
    if [ $? == 1 ]; then
        echo "*******************IDFLAKIES DEBUG************************"
        echo "Building docker image for project"
        date
        bash build_docker_image.sh ${image} ${modifiedslug}
    fi

    # Run the Docker image if it exists
    docker inspect ${image} > /dev/null 2>&1
    if [ $? == 1 ]
    then
        echo "${image} NOT BUILT PROPERLY, LIKELY TESTS FAILED"
    else
	if [ -p SCRIPTEND -o -p DATAREAD ]
	then
	    echo "Named pipes exist. Previous run has likely terminated abnormally! Removing now to continue..."
	    rm SCRIPTEND
	    rm DATAREAD
	fi
	mkfifo --mode=777 SCRIPTEND
	mkfifo --mode=777 DATAREAD
	# kill any running docker containers before running this one
	for hash in $(docker ps -q); do docker kill $hash; echo "Container $hash killed."; done
	export SYSFSRESULTS_DIR=$SCRIPT_DIR/sysfsresults/$modifiedslug
	./wait_for_docker_completion.sh &
	if [ $THROTTLING_NIC = 'ON' ]
	then
	    for i in $(sudo ifconfig |grep '.*: ' |cut -d':' -f1); do wondershaper $i ${THROTTLING_NIC_DOWN} ${THROTTLING_NIC_UP}; done
	fi
        docker run -t --rm ${THROTTLING_CPUSET} ${THROTTLING_CPUS} ${THROTTLING_MEM} ${THROTTLING_SWAP} ${THROTTLING_OOM} ${THROTTLING_READ_BPS} ${THROTTLING_WRITE_BPS} ${THROTTLING_READ_IOPS} ${THROTTLING_WRITE_IOPS} -v ${SCRIPT_DIR}:/Scratch ${image} /bin/bash -xc "/Scratch/run_experiment.sh ${slug} ${rounds} ${timeout} ${script}" # |ts "[ %F %H:%M:%.S ]"
	if [ $THROTTLING_NIC = 'ON' ]
	then
	    for i in $(sudo ifconfig |grep '.*: ' |cut -d':' -f1); do wondershaper clear $i; done
	fi
    fi
done
