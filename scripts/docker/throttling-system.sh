#!/bin/bash

# network throttling
export THROTTLING_NIC='OFF'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33

# IOPS
export IOPSR=100
export IOPSW=100

# IO BPS
export BPSR=100kb
export BPSW=100kb

# memory
export MEM=500m

# CPU
export CPUFRAC=.3
export CPUCOUNT=1
