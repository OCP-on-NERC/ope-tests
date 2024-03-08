#!/bin/bash

create_resource_command=( oc create -f- )

while getopts t:n:d ch; do
    case $ch in
        t)  test_run_name=$OPTARG
            ;;

	    n)  namespace=$OPTARG
            ;;

	# Send manifests to stdout instead of creating resources
        d)  create_resource_command=( cat )
            ;;

        *)  exit 2
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 [-d] [-n <namespace>] [-t <test-run-name>] <num_notebooks> <batch_size> <username> <image_name>" >&2
    exit 1
fi

# Number of notebbooks to create
num_notebooks=$1

# Number of requests to make concurrently
batch_size=$2

# RHODS username
username=$3

# Notebook imagename
image_name=$4

if [[ -z $test_run_name ]]; then
    test_run_name="$(mktemp -u ope-test-"$username"-"$num_notebooks"-XXXXXX)"
fi

if [[ -z $namespace ]]; then
    # use current namespace by default
    namespace="$(oc config view --minify -o jsonpath='{.contexts[0].context.namespace}')"
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
            -p USERNAME="$username" \
            -p IMAGE_NAME="$image_name" \
	    -p NAMESPACE="$namespace" |
            "${create_resource_command[@]}"
    done
    # Wait for the current batch to finish before starting the next
    wait
done

echo "All notebooks are starting. The total requests time is $SECONDS seconds."


