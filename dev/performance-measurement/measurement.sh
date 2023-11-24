#!/usr/bin/env bash
set -e

# OUTDIR will have a default value of measurement, but can be overwritten
OUTDIR=${OUTDIR:-measurements}
mkdir -p "${OUTDIR}"

cleanup() {
    # Kill background processes
    pkill -P $$
    exit
}

trap cleanup EXIT

measure_cpu_usage() {
    local pid="$1"
    local name="$2"
    local output_file="${OUTDIR}/${name}_${pid}_cpu_usage.log"

    while true; do
        local cpu_usage=$(ps -p "$pid" -o %cpu | awk 'NR>1')
        local current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

        echo "$current_time $cpu_usage" >> "$output_file"
        sleep 1
    done
}

network_usage_snapshot() {
	nettop -x -L 1 -P \
	-k interface -k state -k rx_dupe -k rx_ooo -k re-tx -k rtt_avg -k rcvsize -k tx_win -k tc_class -k tc_mgt -k cc_algo -k P -k C -kR -k W -k arch \
	> "${OUTDIR}/network-snapshot-$(date +"%Y-%m-%d--%H-%M-%S").csv"
}

execute_with_measurement() {
    local name="$1"

	shift 1

    # Start the binary with its arguments and obtain the PID
    "$@" > "${OUTDIR}/${name}_output.log" 2>&1 &
    local pid=$!

    # Run the CPU measurement script in the background
    measure_cpu_usage "$pid" "$name" &
}

start_relay_with_measurement() {
	local name="$1"
	local port="$2"
	shift 2
	local args="$@"
	execute_with_measurement "${name}" target/release/moq-relay --listen "[::]:${port}" --tls-cert ./dev/localhost.crt --tls-key ./dev/localhost.key --api http://localhost:4442 --api-node "https://localhost:${port}" --dev $args
}

start_clock_subscribe() {
	local port="$1"
	local track="$2"
	target/release/moq-clock "https://localhost:${port}/${track}" > "${OUTDIR}/${track}_sub_$!_on_${port}.log" 2>&1
}
