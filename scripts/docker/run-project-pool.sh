#!/bin/bash

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - The script to run (Optional)"
    echo "arg5 - Index to start counting rounds from"
    exit
fi

export runIdHash="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')"

mkdir -p "logs"
fname="logs/$(basename $1 .csv)-$runIdHash-runlog.txt"

echo "Logging to $fname"
bash create_and_run_dockers-pool.sh $@ &>> $fname
echo "Finished running $fname"

