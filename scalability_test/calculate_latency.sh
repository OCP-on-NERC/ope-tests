#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <test_name> <namespace>" >&2
    exit 1
fi

test_name=$1
namespace=$2

pods_info=$(oc get pods -n "$namespace" -o json | jq -c --arg test_name "$test_name" '.items[] | select(.metadata.name | startswith($test_name)) | {name: .metadata.name, startTime: .status.startTime, readyTransitionTime: (.status.conditions[] | select(.type=="Ready").lastTransitionTime)}')
sum_latency=0
count=0

while read -r line; do

    name=$(echo "$line" | jq -r '.name')
    start_time=$(echo "$line" | jq -r '.startTime')
    ready_time=$(echo "$line" | jq -r '.readyTransitionTime')

    start_sec=$(date -d "$start_time" +%s)
    ready_sec=$(date -d "$ready_time" +%s)

    latency=$((ready_sec - start_sec))
    echo "latency $latency"

    sum_latency=$((sum_latency + latency))
    count=$((count + 1))

done  < <(echo "$pods_info")

if [ "$count" -gt 0 ]; then
    avg_latency=$((sum_latency / count))
    echo "Average latency: $avg_latency seconds"
else
    echo "No pods found."
fi



