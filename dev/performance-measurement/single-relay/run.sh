#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./dev/performance-measurement/measurement.sh

# launch api
./dev/api &
# launch relay processes, while writing their resource usage to files
start_relay_with_measurement relay1 4443
sleep 5
# launch clock publishers, write output to file
target/release/moq-clock https://localhost:4443/clock1 --publish > /dev/null &
sleep 3
# launch clock subscribers, write output to file

for ((p = 0; p < 2; p++)); do
	target/release/moq-clock https://localhost:4443/clock${p} --publish > /dev/null &
	sleep 3
	for ((s = 0; s < 20; s++)); do
		start_clock_subscribe 4443 clock${p} &
		sleep 1
	done

done

# Sleep for some time
sleep 60
