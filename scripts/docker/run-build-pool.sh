#!/bin/bash

if [[ $1 == "" ]]; then
    echo "arg1 - Path to CSV file with project,sha"
    exit
fi

echo $1

mkdir -p "logs"
fname="logs/$(basename $1 .csv)-buildlog.txt"

echo "Logging to $fname"
bash build_docker_image-pool.sh $@ &> $fname
echo "Finished running $fname"

