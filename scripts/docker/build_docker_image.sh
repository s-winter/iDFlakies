#!/bin/bash

podman build -t $1 - < $2_Dockerfile
