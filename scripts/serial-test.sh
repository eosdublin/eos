#!/bin/bash
set -e # exit on failure of any "simple" command (excludes &&, ||, or | chains)
PATH=\$PATH:~/opt/mongodb/bin
echo "Extracting build directory..."
tar -zxf build.tar.gz
echo "Starting MongoDB..."
~/bin/mongod --fork --dbpath ~/data/mongodb -f ~/etc/mongod.conf --logpath "$(pwd)"/mongod.log
cd /data/job/build
echo "Running tests..."
CPU_CORES=$(getconf _NPROCESSORS_ONLN)
echo "$CPU_CORES cpu cores detected."
TEST_COUNT=$(ctest -N -L nonparallelizable_tests | grep -i 'Total Tests: ' | cut -d ':' -f 2 | awk '{print $1}')
[[ $TEST_COUNT > 0 ]] && echo "$TEST_COUNT tests found." || (echo "ERROR: No tests registered with ctest! Exiting..." && exit 1)
echo "$ ctest -j $CPU_CORES -L nonparallelizable_tests --output-on-failure -T Test"
ctest -j $CPU_CORES -L nonparallelizable_tests --output-on-failure -T Test
echo "Uploading xUnit test results XML file..."
XML_FILENAME="test-results.xml"
mv $(pwd)/Testing/$(ls $(pwd)/Testing/ | grep '20' | tail -n 1)/Test.xml $XML_FILENAME
buildkite-agent artifact upload $XML_FILENAME
echo "Done uploading $XML_FILENAME."
