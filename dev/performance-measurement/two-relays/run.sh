#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./dev/performance-measurement/measurement.sh

# launch api
./dev/api &
# launch relay processes, while writing their resource usage to files
start_relay_with_measurement relay1 4443
start_relay_with_measurement relay2 4444
sleep 3

# launch clock publishers
for ((p = 0; p < 10; p++)); do
	target/release/moq-clock https://localhost:4443/clock${p} --publish > /dev/null &
	sleep 1
done


# subscribers
for ((p = 0; p < 10; p++)); do
	for ((s = 0; s < 40; s++)); do
		start_clock_subscribe 4444 clock${p} &
		sleep 0.3
	done
	sleep 1
done

# Sleep for some time (conduct measurements)
sleep 60
