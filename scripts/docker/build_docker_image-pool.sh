#!/bin/bash

[ $1 == "" ] && { echo "arg1 - CSV file with project URL & commit SHA"; exit 1; }
projfile=$1

for line in $(cat ${projfile}); do
    # Create the corresponding Dockerfile
    slug=$(echo ${line} | cut -d',' -f1 | rev | cut -d'/' -f1-2 | rev)
    sha=$(echo ${line} | cut -d',' -f2)
    ./create_dockerfile.sh ${slug} ${sha}

    # Build the Docker image if does not exist
    modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')
    image=detector-${modifiedslug}:latest
    docker inspect ${image} > /dev/null 2>&1
    if [ $? == 1 ]; then
        echo "*******************IDFLAKIES DEBUG************************"
        echo "Building docker image for project"
        date
        bash build_docker_image.sh ${image} ${modifiedslug}
    fi
done
