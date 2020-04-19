#!/bin/bash

# network throttling
export THROTTLING_NIC='ON'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33

# IOPS
export IOPSR=55
export IOPSW=55

# IO BPS
export BPSR=3500kb
export BPSW=3500kb

# memory
export MEM=128m

# CPU
export CPUFRAC=.1
export CPUCOUNT=1
