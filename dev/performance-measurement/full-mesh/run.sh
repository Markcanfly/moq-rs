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
sleep 6

#!/usr/bin/env bash
# shellcheck source=/dev/null
source ./dev/performance-measurement/measurement.sh

FIRST_EDGE_RELAY_PORT=4443
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
