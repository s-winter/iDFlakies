#!/bin/bash

export THROTTLING_CPUSET='--cpuset-cpus=0'
export THROTTLING_CPUS='--cpus=.01'
export THROTTLING_MEM='--memory=500m'
export THROTTLING_SWAP='--memory-swap=-1'
export THROTTLING_OOM='--oom-kill-disable'
export THROTTLING_READ_IOPS='--device-read-iops /dev/sda:10'
export THROTTLING_WRITE_IOPS='--device-write-iops /dev/sda:10'
export THROTTLING_READ_BPS='--device-read-bps /dev/sda:1k'
export THROTTLING_WRITE_BPS='--device-write-bps /dev/sda:1k'
export THROTTLING_NIC='ON'
export THROTTLING_NIC_DOWN=53
export THROTTLING_NIC_UP=33
