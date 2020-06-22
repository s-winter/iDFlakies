#!/bin/bash

SCRIPT_USERNAME="idflakies"
TOOL_REPO="iDFlakies"

date

# This script is run inside the Docker image, for single experiment (one project)

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]] || [[ $4 == "" ]]; then
    echo "arg1 - GitHub SLUG"
    echo "arg2 - Number of rounds"
    echo "arg3 - Timeout in seconds"
    echo "arg4 - Test name (Optional)"
    echo "arg5 - Round index to start from"
    echo "arg6 - runId" 
    exit
fi

slug=$1
rounds=$2
timeout=$3
fullTestName=$4
roundsStart=$5
runId=$6

[[ -z $roundsStart ]] && roundsStart=1

echo "Slug: ${slug}"
echo "Rounds: ${rounds}"
echo "Timeout: ${timeout}"
echo "fullTestName: ${fullTestName}"
echo "roundsStart: ${roundsStart}"
echo "runId: ${runId}"

modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')

# the following named pipes are used for synchronization with the host
# right before the script ends, SCRIPTEND is signaled by the script running inside the container
# then the host reads cgroup accounting data from sysfs and signals DATAREAD to indicate that the script can finish
[ -w /Scratch/SCRIPTEND_${runId} ] || { echo "SCRIPTEND named pipe for host synchronization does not exist or is not writable"; exit 1; }
[ -r /Scratch/DATAREAD_${runId} ] || { echo "DATAREAD named pipe for host synchronization does not exist or is not writable"; exit 1; }

# Incorporate tooling into the project, using Java XML parsing
# cd "/home/$SCRIPT_USERNAME/${slug}"
# /home/$SCRIPT_USERNAME/$TOOL_REPO/scripts/docker/pom-modify/modify-project.sh . 1.0.1-SNAPSHOT

export PATH=/home/$SCRIPT_USERNAME/apache-maven/bin:$PATH

cd /home/$SCRIPT_USERNAME/

cd /home/$SCRIPT_USERNAME/${slug}

# Set global mvn options for skipping things
MVNOPTIONS="-Ddependency-check.skip=true -Dgpg.skip=true -DfailIfNoTests=false -Dskip.installnodenpm -Dskip.npm -Dskip.yarn -Dlicense.skip -Dcheckstyle.skip -Drat.skip -Denforcer.skip -Danimal.sniffer.skip -Dmaven.javadoc.skip -Dfindbugs.skip -Dwarbucks.skip -Dmodernizer.skip -Dimpsort.skip -Dmdep.analyze.skip -Dpgpverify.skip -Dxml.skip"

if [[ $fullTestName == "org.apache.hadoop.hbase.regionserver.TestSyncTimeRangeTracker" || $fullTestName == "org.apache.hadoop.hbase.snapshot.TestMobRestoreSnapshotHelper" ]]; then
    formatTest="$(echo $fullTestName | rev | cut -d. -f2 | rev)"
    class="$(echo $fullTestName | rev | cut -d. -f2 | rev)"
else
    formatTest="$(echo $fullTestName | rev | cut -d. -f2 | rev)#$(echo $fullTestName | rev | cut -d. -f1 | rev )"
    class="$(echo $fullTestName | rev | cut -d. -f2 | rev)"
fi

echo "formatTest: $formatTest"
echo "class: $class"

classloc=$(find -name $class.java)
if [[ -z $classloc ]]; then
    echo "exit: 100 No test class at this commit."
    exit 100
fi

classcount=$(find -name $class.java | wc -l)
if [[ "$classcount" != "1" ]]; then
    classloc=$(find -name $class.java | head -n 1)
    echo "Multiple test class found. Unsure which one to use. Choosing: $classloc. Other ones are:"
    find -name $class.java
fi

module=$classloc
while [[ "$module" != "." && "$module" != "" ]]; do
    module=$(echo $module | rev | cut -d'/' -f2- | rev)
    echo "Checking for pom at: $module"
    if [[ -f $module/pom.xml ]]; then
	break;
    fi
done
echo "Location of module: $module"

RESULTSDIR=/Scratch/output/$modifiedslug_$module
mkdir -p ${RESULTSDIR}

# Run the plugin, original order
echo "*******************REED************************"
echo "Running mvn test on $module"
date

echo "" > rounds-test-results.csv
for ((i=roundsStart;i<roundsStart+rounds;i++)); do
    echo "Iteration: $((i-roundsStart+1)) / $rounds"
    export mvnTestRound=$i

    /usr/bin/time -v mvn test -pl $module ${MVNOPTIONS} |& tee mvn-test-$i.log

    mkdir -p ${RESULTSDIR}/$i
    mv mvn-test-$i.log ${RESULTSDIR}/$i
done

echo "*******************REED************************"
echo "Finished run_project.sh"
date

# synchronization with docker host; see top of this file where existence of these pipes is checked for more details
echo </dev/null >/Scratch/SCRIPTEND_${runId}
cat </Scratch/DATAREAD_${runId} >/dev/null
