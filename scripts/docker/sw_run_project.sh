#!/bin/bash

SCRIPT_USERNAME="idflakies"
TOOL_REPO="iDFlakies"

date

# This script is run inside the Docker image, for single experiment (one project)

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
    echo "arg1 - GitHub SLUG"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    exit
fi

# the following named pipes are used for synchronization with the host
# right before the script ends, SCRIPTEND is signaled by the script running inside the container
# then the host reads cgroup accounting data from sysfs and signals DATAREAD to indicate that the script can finish
[ -w /Scratch/SCRIPTEND ] || { echo "SCRIPTEND named pipe for host synchronization does not exist or is not writable"; exit 1; }
[ -r /Scratch/DATAREAD ] || { echo "DATAREAD named pipe for host synchronization does not exist or is not writable"; exit 1; }

slug=$1
rounds=$2
timeout=$3

# Incorporate tooling into the project, using Java XML parsing
cd "/home/$SCRIPT_USERNAME/${slug}"
/home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/docker/pom-modify/modify-project.sh . 1.0.1-SNAPSHOT

# Set global mvn options for skipping things
MVNOPTIONS="-Denforcer.skip=true -Drat.skip=true -Dmdep.analyze.skip=true -Dmaven.javadoc.skip=true"

# Optional timeout... In practice our tools really shouldn't need 1hr to parse a project's surefire reports.
# timeout 1h /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Dtestplugin.className=edu.illinois.cs.dt.tools.utility.ModuleTestTimePlugin -fn -B -e |& tee module_test_time.log

# # Run the plugin, reversing the original order (reverse class and methods)
# echo "*******************REED************************"
# echo "Running testplugin for reversing the original order"
# date

# timeout 4000s /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddetector.timeout=4000 -Ddt.randomize.rounds=${rounds} -Ddetector.detector_type=reverse -fn -B -e |& tee reverse_original.log


# # Run the plugin, reversing the original order (reverse class)
# echo "*******************REED************************"
# echo "Running testplugin for reversing the class order"
# date

# timeout 4000s /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddetector.timeout=4000 -Ddt.randomize.rounds=${rounds} -Ddetector.detector_type=reverse-class -fn -B -e |& tee reverse_class.log


# Run the plugin, original order
echo "*******************REED************************"
echo "Running testplugin for original"
date

timeout 3600s /usr/bin/time -v /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddt.randomize.rounds=${rounds} -Ddetector.detector_type=original -Ddt.detector.original_order.retry_count=1 -Ddt.detector.original_order.all_must_pass=false -Ddt.mvn_test.must_pass=false -Ddt.detector.roundsemantics.total=true -fn -B -e |& tee original.log


# # Run the plugin, random class first, method second
# echo "*******************REED************************"
# echo "Running testplugin for randomizemethods"
# date

# timeout ${timeout}s /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddetector.timeout=${timeout} -Ddt.randomize.rounds=${rounds} -fn -B -e |& tee random_class_method.log


# # Run the plugin, random class only
# echo "*******************REED************************"
# echo "Running testplugin for randomizeclasses"
# date

# timeout ${timeout}s /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddetector.timeout=${timeout} -Ddt.randomize.rounds=${rounds} -Ddetector.detector_type=random-class -fn -B -e |& tee random_class.log

# # Run the smart-shuffle (every test runs first and last)
# echo "*******************REED************************"
# echo "Running testplugin for smart-shuffle"
# date

# timeout ${timeout}s /home/$SCRIPT_USERNAME/apache-maven/bin/mvn testrunner:testplugin ${MVNOPTIONS} -Ddetector.timeout=${timeout} -Ddt.randomize.rounds=${rounds} -Ddetector.detector_type=smart-shuffle -fn -B -e |& tee smart_shuffle.log


# Gather the results, put them up top
RESULTSDIR=/home/$SCRIPT_USERNAME/output/
mkdir -p ${RESULTSDIR}
/home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/gather-results $(pwd) ${RESULTSDIR}
mv *.log ${RESULTSDIR}/


echo "*******************REED************************"
echo "Finished run_project.sh"
date

# synchronization with docker host; see top of this file where existence of these pipes is checked for more details
echo </dev/null >/Scratch/SCRIPTEND
cat </Scratch/DATAREAD >/dev/null