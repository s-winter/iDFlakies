#!/bin/bash

# CPU throttling: CPU(s) used and CPU time
export THROTTLING_CPUSET='--cpuset-cpus=0,1'
export THROTTLING_CPUS='--cpus=.1'

# Memory throttling: Main memory available, swap space available (-1 means unlimited, 0 means no swapping, else must be larger than memory), oom killer disabling
export THROTTLING_MEM='--memory=500m'
export THROTTLING_SWAP='--memory-swap=-1'
export THROTTLING_OOM='--oom-kill-disable'

# blkio ops throttling (useful for workloads with small files)
export THROTTLING_READ_IOPS='--device-read-iops=/dev/sda:10'
export THROTTLING_WRITE_IOPS='--device-write-iops=/dev/sda:10'

# blkio throughput throttling (useful for workloads with large files)
export THROTTLING_READ_BPS='--device-read-bps=/dev/sda:1k'
export THROTTLING_WRITE_BPS='--device-write-bps=/dev/sda:1k'

# network throttling
export THROTTLING_NIC='ON'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33
