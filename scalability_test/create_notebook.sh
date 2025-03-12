#!/bin/bash

create_resource_command=( oc create -f- )

csv_name="/dev/null"

rate_limit = 0.5

while getopts a:t:n:r:c:d ch; do
    case $ch in
	r)  rate_limit=$OPTARG
	    ;;

        t)  test_run_name=$OPTARG
            ;;

	n)  namespace=$OPTARG
            ;;

	# Send manifests to stdout instead of creating resources
        d)  create_resource_command=( cat )
            ;;

	c)  csv_name=$OPTARG
            ;;

	# TinyURL API token
	a) api_token=$OPTARG
	    ;;

        *)  exit 2
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 [-d] [-a <TinyURL API Token>] [-r <rate_limit>] [-n <namespace>] [-t <test-run-name>] [-c <tiny_url_csv_filename>] <num_notebooks> <batch_size> <username> <image_name>" >&2
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
#test_run_name="${test_run_name,,}"

# SECONDS is a magic bash variable that will return the number of
# elapsed seconds since it was set to 0.
SECONDS=0

echo "Starting test run $test_run_name with $num_notebooks notebooks" 

echo "URL,Domain,Alias,Tag" > $csv_name

for ((i=0; i<num_notebooks; i+=batch_size)); do
    for ((j=0; j<batch_size && (i+j)<num_notebooks; j++)); do
	random_id=`openssl rand -hex 3`
        notebook_name="${test_run_name}-${random_id}"
	url="https://bmfm-${random_id}-ai4dd-06afdc.apps.shift.nerc.mghpcc.org/notebook/ai4dd-06afdc/bmfm-${random_id}/lab/workspaces/auto-s/tree/openad_notebooks/BMFM_HOL.ipynb"
	alias="ai4dd-${random_id}"
	echo "${url},tinyurl.com,${alias},demo" >> $csv_name
        oc process -f test_resources.yaml --local \
            -p NOTEBOOK_NAME="$notebook_name" \
            -p TEST_RUN_NAME="$test_run_name" \
            -p USERNAME="$username" \
            -p IMAGE_NAME="$image_name" \
	    -p NAMESPACE="$namespace" |
            "${create_resource_command[@]}"
	if [[ -z $api_token ]]; then
	  python add_tiny_url.txt --token $api_token --url $url --domain tinyurl.com --alias $alias --tags demo
	  sleep $rate_limit
	fi
    done
    # Wait for the current batch to finish before starting the next
    wait
done

echo "All notebooks are starting. The total time for requests is $SECONDS seconds."


