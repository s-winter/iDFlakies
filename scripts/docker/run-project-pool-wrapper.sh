#!/bin/bash

instances=$5

source $1/throttling.sh
find "$1" -maxdepth 1 -type f -name "*.csv" | xargs -P"$instances" -I{} bash run-project-pool.sh {} "$2" "$3" "$4"
