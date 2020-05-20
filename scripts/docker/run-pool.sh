#!/usr/bin/env zsh

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha,module"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - The script to run (Optional)"
    echo "arg5 - Number of processes to run at the same time (Optional)"
    exit
fi

csvDir="$1"

PROCESS_NUM="$5"
physProcs=$(nproc --all)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [[ -z "$PROCESS_NUM" ]]; then
    # default: use at most a quarter of the existing cores for building
    PROCESS_NUM=$(($physProcs/4))
fi

if (($PROCESS_NUM > $physProcs)); then
    echo "More processes specified than processors available -- exiting"
    exit 1
fi

# [ -f $SCRIPT_DIR/throttling-system.sh ] || { echo "No throttling definitions found"; exit 1; }
# source $SCRIPT_DIR/throttling-system.sh

echo "*******************IDFLAKIES DEBUG************************"
echo "Making base image"
date

# Create base Docker image if does not exist
docker inspect detectorbase:latest > /dev/null 2>&1
if  [ "$?" = "1" ]; then
    docker build -t detectorbase:latest - < baseDockerfile
fi

# echo "*******************IDFLAKIES DEBUG************************"
# echo "Making tooling image"
# date

# Create tooling Docker image if does not exist
# docker inspect toolingdetectorbase:latest > /dev/null 2>&1
# if  [ "$?" = "1" ]; then
#     docker build -t toolingdetectorbase:latest - < toolingDockerfile
# fi

projectCSVs=$(find $csvDir -maxdepth 1 -type f -name "*.csv")
typeset -A uniqueProjectCSVs
for p in ${projectCSVs}; do
    if [[ -z ${uniqueProjectCSVs[${p%%_output-*}] ]]
	uniqueProjectCSVs[${p%%_output-*}]=$p
echo $uniqueProjectCSVs | xargs -P"$PROCESS_NUM" -I{} bash run-build-pool.sh {}

# CPUCOUNT is an integer defined in throttling-system.sh
# cpuGroups=$(($physProcs / $CPUCOUNT))
# declare -a CPUs
# for d in {1..$cpuGroups}; do
#     mkdir -p ${csvDir}/eGroup$d
#     CPUs[$d]=$(seq -s',' $((($d-1) * $CPUCOUNT)) $(($d * $CPUCOUNT - 1)))
# done
# i=0
# CPUFRAC is a float defined in throttling-system.sh that specifies what fraction of CPU time the container gets
# CPU time is *per core*, which is why we scale according to CPU count:
# CPUFRAC=$(printf '%.1f' $((CPUFRAC * CPUCOUNT)))
# for p in $(echo $projectCSVs); do
#     index=$(($i % $PROCESS_NUM + 1))
#     dirPath=${csvDir}/eGroup$index
#     cp $p $dirPath
#     throttlingFilePath=$dirPath/throttling.sh
#     cp throttling-template.sh $throttlingFilePath
#     sed -i "s:\$CPUSET:$CPUs[$index]:" $throttlingFilePath
#     sed -i "s:\$CPUFRAC:$CPUFRAC:" $throttlingFilePath
#     ((++i))
# done

# we divide 1 (for the compute time of 1 cpuGroup) by *twice* the CPUFRAC to keep CPUs idle at least 50% of time if CPUFRAC <= 50%
# the reason for limiting the load of parallel instances on the same CPU group is to limit side effects from our parallelization
# we cut off everything after the decimal dot to get the number of instances we can run on each CPU group
# if (($CPUFRAC > .5));
# then
#    perGroupInstances=1
# else
#     perGroupInstances=${$((1/(($CPUFRAC * 2))))%.*}
# fi

# in some scenarios we will have fewer csv files than possible eGroups
# to avoid false positive warnings during execution, we remove the resulting empty directories
# for d in {1..$cpuGroups}; do
#     dirname=${csvDir}/eGroup${d}
#     [ -z "$(ls -A ${dirname})" ] && rmdir $dirname
# done

# if [ "$THROTTLING_NIC" = 'ON' ]
# then
#     for i in $(sudo ifconfig |grep '.*: ' |cut -d':' -f1); do sudo wondershaper $i ${THROTTLING_NIC_DOWN} ${THROTTLING_NIC_UP}; done
# fi
#find $csvDir -maxdepth 1 -type d -name "eGroup*" | xargs -P"$cpuGroups" -I{} bash run-project-pool-wrapper.sh {} "$2" "$3" "$4" "$perGroupInstances"
find $csvDir -maxdepth 1 -type f -name "*.csv" | xargs -P"$PROCESS_NUM" -I{} bash run-project-pool.sh {} "$2" "$3" "$4"

# if [ "$THROTTLING_NIC" = 'ON' ]
# then
#     for i in $(sudo ifconfig |grep '.*: ' |cut -d':' -f1); do sudo wondershaper clear $i; done
# fi
