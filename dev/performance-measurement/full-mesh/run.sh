#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./dev/performance-measurement/measurement.sh

# launch api
./dev/api &
# launch relay processes, while writing their resource usage to files
start_relay_with_measurement relay1 4443
start_relay_with_measurement relay2 4444
start_relay_with_measurement relay3 4445
start_relay_with_measurement relay4 4446
start_relay_with_measurement relay5 4447
sleep 3

# for each relay
for ((r = 3; r <= 7; r++)); do
	# launch publishers
	for ((p = 0; p < 2; p++)); do
		target/release/moq-clock https://localhost:444${r}/clock${r}-${p} --publish > /dev/null &
		sleep 1
	done
done

# on each relay
for ((r = 3; r <= 7; r++)); do
	# for each other relay
	for ((r1 = 3; r1 <= 7; r1++)); do
		# for each publisher of each relay
		for ((p = 0; p < 2; p++)); do
			# launch 4 subscribers
			for ((i = 0; i < 4; i++)); do
				start_clock_subscribe "444${r}" clock${r1}-${p} &
				sleep 0.8
			done

		done
	done
done

# Measure for some time
sleep 60
