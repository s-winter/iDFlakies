#!/bin/bash

# network throttling
export THROTTLING_NIC='ON'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33

# IOPS
export IOPSR=10
export IOPSW=10

# IO BPS
export BPSR=10kb
export BPSW=10kb

# memory
export MEM=500m

# CPU
export CPUFRAC=.1
export CPUCOUNT=1
