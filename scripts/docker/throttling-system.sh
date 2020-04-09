#!/bin/bash

# network throttling
export THROTTLING_NIC='ON'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33

# IOPS
export IOPSR=1
export IOPSW=1

# IO BPS
export BPSR=1kb
export BPSW=1kb

# memory
export MEM=128m

# CPU
export CPUFRAC=.1
export CPUCOUNT=1
