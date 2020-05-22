#!/bin/bash

SCRIPT_USERNAME="idflakies"
TOOL_REPO="iDFlakies"

# This script is the entry point script that is run inside of the Docker image
# for running the experiment for a single project

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]] || [[ $4 == "" ]]; then
    echo "arg1 - GitHub SLUG"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - docker image name"
    echo "arg5 - Script to run (Optional)"
    echo "arg6 - Script to run parameter: roundIndex"
    echo "arg7 - Script to run parameter: runId"
    exit
fi

# If it's an absolute path, just use it
if [[ "$5" =~ ^/ ]]; then
    script_to_run="$5"
elif [[ -z "$5" ]]; then
    # The default is run_project.sh
    script_to_run="/home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/docker/run_project.sh"
else
    # otherwise, assume it's relative to the docker directory
    script_to_run="/home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/docker/$5"
fi

slug=$1
module=$2
rounds=$3
timeout=$4
image=$5
roundIndex=$6
runId=$7

modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')

mkdir -p /Scratch/all-output/${modifiedslug}_output/
chown "$SCRIPT_USERNAME" /Scratch/all-output/${modifiedslug}_output/
chmod 755 /Scratch/all-output/${modifiedslug}_output/

# Update all tooling
# su - "$SCRIPT_USERNAME" -c "cd /home/$SCRIPT_USERNAME/$TOOL_REPO/; git pull"

# echo "*******************IDFLAKIES DEBUG************************"
# echo "Running update.sh"
# date
# su - "$SCRIPT_USERNAME" -c "/home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/docker/update.sh"

# Copy the test time log, if it is in the old location. Probably can remove this line if all containers are new.

# if [[ -e "/home/$SCRIPT_USERNAME/mvn-test-time.log" ]] && [[ ! -e "/home/$SCRIPT_USERNAME/$slug/mvn-test-time.log" ]]; then
#     cp "/home/$SCRIPT_USERNAME/mvn-test-time.log" "/home/$SCRIPT_USERNAME/$slug"
# fi

# Start the script using the $SCRIPT_USERNAME user
echo ""$script_to_run ${slug} ${rounds} ${timeout} ${image}""
su - "$SCRIPT_USERNAME" -c "$script_to_run ${slug} ${module} ${rounds} ${timeout} ${image} ${roundIndex} ${runId}"

# Change permissions of results and copy outside the Docker image (assume outside mounted under /Scratch)
# mkdir -p "/Scratch/all-output/${modifiedslug}_output/misc-output/"
# cp -r "/home/$SCRIPT_USERNAME/output/" "/Scratch/all-output/${modifiedslug}_output/misc-output/"
# chown -R $(id -u):$(id -g) /Scratch/all-output/${modifiedslug}_output/
# chmod -R 777 /Scratch/all-output/${modifiedslug}_output/

# chown $(id -u):$(id -g) /Scratch/all-output/
# chmod 777 /Scratch/all-output/
