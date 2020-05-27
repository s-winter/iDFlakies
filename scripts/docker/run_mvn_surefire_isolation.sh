#!/bin/bash

SCRIPT_USERNAME="idflakies"
TOOL_REPO="iDFlakies"

echo "*******************REED************************"
echo "Starting run_mvn_surefire.sh"
date

if [[ $1 == "" ]] || [[ $2 == "" ]] || [[ $3 == "" ]]; then
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

# the following named pipes are used for synchronization with the host
# right before the script ends, SCRIPTEND is signaled by the script running inside the container
# then the host reads cgroup accounting data from sysfs and signals DATAREAD to indicate that the script can finish
[ -w /Scratch/SCRIPTEND_${runId} ] || { echo "SCRIPTEND named pipe for host synchronization does not exist or is not writable"; exit 1; }
[ -r /Scratch/DATAREAD_${runId} ] || { echo "DATAREAD named pipe for host synchronization does not exist or is not writable"; exit 1; }

export PATH=/home/$SCRIPT_USERNAME/apache-maven/bin:$PATH

cd /home/$SCRIPT_USERNAME/

modifiedslug=$(echo ${slug} | sed 's;/;.;' | tr '[:upper:]' '[:lower:]')

cd /home/$SCRIPT_USERNAME/${slug}

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

RESULTSDIR=/Scratch/output/${modifiedslug}_${module}_isolation
mkdir -p ${RESULTSDIR}

# if [[ "$slug" == "apache/incubator-dubbo" ]]; then
#     chown -R $USER .
#     mvn clean install -DskipTests ${MVNOPTIONS} |& tee mvn-install.log
# elif [[ "$slug" == "openpojo/openpojo" ]]; then
#     wget https://files-cdn.liferay.com/mirrors/download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.tar.gz
#     tar -zxf jdk-7u80-linux-x64.tar.gz
#     dir=$(pwd)
#     export JAVA_HOME=$dir/jdk1.7.0_80/
#     MVNOPTIONS="${MVNOPTIONS} -Dhttps.protocols=TLSv1.2"
#     mvn clean install -am -pl $module -DskipTests ${MVNOPTIONS} |& tee mvn-install.log
# else
#     mvn clean install -am -pl $module -DskipTests ${MVNOPTIONS} |& tee mvn-install.log
# fi
# ret=${PIPESTATUS[0]}
# mv mvn-install.log ${RESULTSDIR}
# if [[ $ret != 0 ]]; then
#     # mvn install does not compile - return 0
#     echo "Compilation failed. Actual: $ret"
#     exit 1
# fi

# if [[ "$slug" == "dropwizard/dropwizard" ]]; then
#     mvn test ${MVNOPTIONS} |& tee mvn-test.log
# else
#     mvn test -pl $module ${MVNOPTIONS} |& tee mvn-test.log
# fi

# ret=${PIPESTATUS[0]}
# mv mvn-test.log ${RESULTSDIR}

# echo "================Parsing test list"
pip install BeautifulSoup4
pip install lxml

# echo "" > test-results.csv
# for f in $(find $module -name "TEST*.xml"); do
#     python /home/awshi2/dt-fixing-tools/scripts/python-scripts/parse_surefire_report.py $f -1  >> test-results.csv
# done
# cat test-results.csv | sort -u | awk NF > ${RESULTSDIR}/test-results.csv

# oldclass="$(echo $fullTestName | rev | cut -d. -f2 | rev)"
# oldtest="$(echo $fullTestName | rev | cut -d. -f1 | rev )"
# oldtestcount=$(grep "$oldclass.$oldtest," test-results.csv | wc -l)

# if [[ "$oldtestcount" != "1" ]]; then
#     echo "Multiple test names found. Unsure which one to use:"
#     grep "$oldclass.$oldtest," test-results.csv
#     topone=$(grep "$oldclass.$oldtest," test-results.csv | head -n 1)
#     echo "Arbitrarily choosing: $topone"
# fi

# fullClass="$(echo $fullTestName | rev | cut -d. -f2- | rev)"
# testName="$(echo $fullTestName | rev | cut -d. -f1 | rev )"

#mkdir -p ${RESULTSDIR}/isolation
echo "" > rounds-test-results.csv
for ((i=roundsStart;i<roundsStart+rounds;i++)); do
    echo "Iteration: $((i-roundsStart+1)) / $rounds"
    find . -name surefire-reports -type d -exec rm -r {} +
    echo "surefire-reports that were not deleted: $(find . -name surefire-reports -type d)"

    /usr/bin/time -v mvn test -pl $module -Dtest=${formatTest} ${MVNOPTIONS} |& tee mvn-test-$i.log
    for f in $(find -name "TEST*.xml"); do python /Scratch/parse_surefire_report.py $f $i >> rounds-test-results.csv; done

    mkdir -p ${RESULTSDIR}/$i
    mv mvn-test-$i.log ${RESULTSDIR}/$i
    echo "result files..."
    ls ${RESULTSDIR}/$i
    for f in $(find -name "TEST*.xml"); do mv $f ${RESULTSDIR}/$i; done
done

mv rounds-test-results.csv ${RESULTSDIR}/rounds-test-results.$i.csv

echo "*******************REED************************"
echo "Finished run_mvn_surefire.sh"
date

synchronization with docker host; see top of this file where existence of these pipes is checked for more details
echo </dev/null >/Scratch/SCRIPTEND_${runId}
cat </Scratch/DATAREAD_${runId} >/dev/null
