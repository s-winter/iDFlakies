#!/bin/bash

csvDir=$1
rounds=$2
timeout=$3
script=$4
instances=$5
roundStartIndex=$6

source $1/throttling.sh
find "$csvDir" -maxdepth 1 -type f -name "*.csv" -print0 | xargs -0 -P"$instances" -I{} bash run-project-pool.sh {} "$rounds" "$timeout" "$script" "$roundStartIndex"
