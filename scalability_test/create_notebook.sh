#!/bin/bash

while getopts n: ch; do
    case $ch in
        n)  test_run_name=$OPTARG
            ;;

        *)  exit 2
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 [-n <test-run-name>] <num_notebooks> <batch_size> <username>" >&2
    exit 1
fi

# Number of notebbooks to create
num_notebooks=$1

# Number of requests to make concurrently
batch_size=$2

# RHODS username
username=$3

if [[ -z $test_run_name ]]; then
    test_run_name="$(mktemp -u ope-test-"$username"-"$num_notebooks"-XXXXXX)"
fi

# ensure names are lower case
test_run_name="${test_run_name,,}"

# SECONDS is a magic bash variable that will return the number of
# elapsed seconds since it was set to 0.
SECONDS=0

echo "Starting test run $test_run_name with $num_notebooks notebooks"

for ((i=0; i<num_notebooks; i+=batch_size)); do
    for ((j=0; j<batch_size && (i+j)<num_notebooks; j++)); do
        notebook_name="${test_run_name}-$((i+j))"
        oc process -f test_resources.yaml --local \
            -p NOTEBOOK_NAME="$notebook_name" \
            -p TEST_RUN_NAME="$test_run_name" \
            -p USERNAME="$username" |
            oc create -f-
    done
    # Wait for the current batch to finish before starting the next
    wait
done

echo "All notebooks are starting. The total requests time is $SECONDS seconds."
