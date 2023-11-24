#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./dev/performance-measurement/measurement.sh

# Seed RANDOM for repeatability
RANDOM=42

# launch api
./dev/api &
# launch relay processes, while writing their resource usage to files
start_relay_with_measurement spine1 4443
sleep 1
start_relay_with_measurement spine2 4444
sleep 1
start_relay_with_measurement leaf1 4445 --next-relays https://localhost:4443/ --next-relays https://localhost:4444/
sleep 1
start_relay_with_measurement leaf2 4446 --next-relays https://localhost:4443/ --next-relays https://localhost:4444/
sleep 1
start_relay_with_measurement leaf3 4447 --next-relays https://localhost:4443/ --next-relays https://localhost:4444/
sleep 5
start_relay_with_measurement leaf4 4448 --next-relays https://localhost:4443/ --next-relays https://localhost:4444/
sleep 5
start_relay_with_measurement leaf5 4449 --next-relays https://localhost:4443/ --next-relays https://localhost:4444/
sleep 5

FIRST_EDGE_RELAY_PORT=4445
N_EDGE_RELAYS=5
N_PUBLISHERS=16
N_SUBSCRIBERS=400

echo Starting publishers...
for ((p = 0; p < N_PUBLISHERS; p++)); do
	relay_port=$((FIRST_EDGE_RELAY_PORT + p % N_EDGE_RELAYS))
	clock_id=$p
	target/release/moq-clock "https://localhost:${relay_port}/clock${clock_id}" --publish > /dev/null &
	sleep 1
done
echo Publishers started successfully

echo Starting subscribers...
for ((s = 0; s < N_SUBSCRIBERS; s++)); do
	echo "Starting sub ${s}/${N_SUBSCRIBERS}"
	relay_port=$((FIRST_EDGE_RELAY_PORT + s % N_EDGE_RELAYS))
	clock_id=$((RANDOM % N_PUBLISHERS))
	start_clock_subscribe ${relay_port} clock${clock_id} &
	sleep 0.8
done
echo Subscribers started successfully

echo All measurement components started, measuring...
# Measure for some time
network_usage_snapshot
sleep 120
network_usage_snapshot
