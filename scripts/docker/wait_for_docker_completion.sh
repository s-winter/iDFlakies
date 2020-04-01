#!/bin/bash

# This script waits for an iDFlakies project docker container to complete execution and gets sysfs data just before it exits.
# The synchronization of the execution order <docker workload finishes, sysfs is read, docker exits> is ensured via two named pipes, SCRIPTEND and DATAREAD.
# These pipes are created in the create_and_run_dockers.sh script, from which this script is called.
# The other ends of the pipes are read/written in the sw_run_project.sh script, i.e., for this to work that script needs to be passed to create_and_run_dockers.sh as the script to run inside docker.
# This mechanism currently assumes that only one docker container is running at a time. This assumption is enforced in the create_and_run_dockers.sh script.

[ $1 == "" ] || [ $2 == "" ] && { echo "arg1 - Name of docker image tag"; echo "arg2 - Modified Slug"; exit 1; }
image=$1

cat <SCRIPTEND_${image} >/dev/null

echo "************* Collecting sysfs performance data *************"

mkdir -p $SYSFSRESULTS_DIR
#_${modifiedslug}

dockerHash=$(docker ps --no-trunc | grep ${image} | tr -s ' ' | cut -d' ' -f1)

# get memory stats

mkdir -p $SYSFSRESULTS_DIR/memory
sudo cp /sys/fs/cgroup/memory/docker/$dockerHash/* $SYSFSRESULTS_DIR/memory

# get CPU stats

mkdir -p $SYSFSRESULTS_DIR/cpu
sudo cp /sys/fs/cgroup/cpu,cpuacct/docker/$dockerHash/* $SYSFSRESULTS_DIR/cpu

# if you prefer a single file with all the data, try the following:
# for f in $(ls /sys/fs/cgroup/cpu,cpuacct/docker/$dockerHash); do echo "$f: $(cat $f | sed -e 'H;${x;s/\n/,/g;s/^,//;p;};d')" >>$SYSFSRESULTS_DIR/cpustats.txt; done
# should work analogously for other resources

# get blkio stats

mkdir -p $SYSFSRESULTS_DIR/blkio
sudo cp /sys/fs/cgroup/blkio/docker/$dockerHash/* $SYSFSRESULTS_DIR/blkio

# get NIC stats
# We can get all RX and TX register values from the docker container's virtual NIC: https://docs.docker.com/config/containers/runmetrics/#network-metrics
# For this to work in a script, edit the sudoers file and add a line:
# <host username>   ALL=(ALL:ALL) NOPASSWD: /bin/ip
# If this does not work, also add a corresponding line for /bin/netstat
# As far as I know, these lines need to be the last lines, as they constitute exceptions to (likely existing) more general rules in the file.
# On my machine I have manually created the /var/run/netns directory as super user and then changed ownership to my local user.
# Alternatively, one can do this here via sudo, which requires yet another entry in the sudoers file.

TASKS=/sys/fs/cgroup/devices/docker/$dockerHash/tasks
PID=$(head -n 1 $TASKS)
sudo mkdir -p /var/run/netns
sudo ln -sf /proc/$PID/ns/net /var/run/netns/$dockerHash
sudo ip netns exec $dockerHash netstat -i >>$SYSFSRESULTS_DIR/netstat.txt
sudo rm /var/run/netns/$dockerHash

echo "************* Finished performance data collection  *************"

echo </dev/null >DATAREAD_${image}

rm SCRIPTEND_${image}
rm DATAREAD_${image}
