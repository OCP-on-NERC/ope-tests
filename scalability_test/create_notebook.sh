#!/bin/bash

create_resource_command=( oc create -f- )
csv_name="/dev/null"
notebook_token_enabled="false" # Default: do not generate notebook tokens
shorten_url="false" # Default: do not shorten URLs
rate_limit=0.5
tiny_url_api_token=${TINY_URL_API_TOKEN:-""} # Read from environment variable

# default image registry
image_repo="image-registry.openshift-image-registry.svc:5000/redhat-ods-applications"

while getopts t:n:c:e:s:d:r ch; do
    case $ch in
        t)  test_run_name=$OPTARG
            ;;

	    n)  namespace=$OPTARG
            ;;

        c)  tiny_url_csv_filename=$OPTARG
            ;;

        e)  notebook_token_enabled=$OPTARG
            ;;

        s)  shorten_url=$OPTARG
            ;;
	# Send manifests to stdout instead of creating resources
        d)  create_resource_command=( cat )
            ;;
    #if registry is different than rhods-ods-applications
        r) image_repo=$OPTARG
            ;;

        *)  exit 2
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 [-d] [-n <namespace>] [-t <test-run-name>] [-c <tiny_url_csv_filename>] [-e <enable_notebook_token: true|false>] [-s <shorten_url: true|false>] [-r <image-registry>] <num_notebooks> <batch_size> <username> <image_name>" >&2
    echo "Environment Variable:"
    echo "TINY_URL_API_TOKEN: (Optional) API token for TinyURL service."
    echo "Set -s to true to shorten url"
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

# Openshift url
openshift_url=$5

host="${openshift_url%/projects*}"        # get everything before projects
hub_host=$host

if [[ -z $test_run_name ]]; then
    test_run_name="$(mktemp -u ope-test-"$username"-"$num_notebooks"-XXXXXX)"
fi

if [[ -z $namespace ]]; then
    # use current namespace by default
    namespace="$(oc config view --minify -o jsonpath='{.contexts[0].context.namespace}')"
fi

if [[ $tiny_url_csv_filename ]]; then
    csv_name="${tiny_url_csv_filename}"
fi

# ensure names are lower case
test_run_name="${test_run_name,,}"
notebook_token_enabled="${notebook_token_enabled,,}"
shorten_url="${shorten_url,,}"

# SECONDS is a magic bash variable that will return the number of
# elapsed seconds since it was set to 0.
SECONDS=0

echo "Starting test run $test_run_name with $num_notebooks notebooks"
echo "URL,Domain,Alias,NB_Token,Tag" > $csv_name

for ((i=0; i<num_notebooks; i+=batch_size)); do
    for ((j=0; j<batch_size && (i+j)<num_notebooks; j++)); do
        random_id=$(openssl rand -hex 3)
        notebook_token=""
        if [[ "$notebook_token_enabled" == "true" ]]; then
            notebook_token=$(openssl rand -hex 6)  # Generate a real token
        fi

        notebook_name="${test_run_name}-${random_id}"
        url="https://${notebook_name}-${namespace}.apps.shift.nerc.mghpcc.org/notebook/${namespace}/${notebook_name}/lab"
        alias="ope-${random_id}"
        echo "${url},tinyurl.com,${alias},${notebook_token},demo" >> "$csv_name"

        params=(
            -p NOTEBOOK_NAME="$notebook_name"
            -p TEST_RUN_NAME="$test_run_name"
            -p USERNAME="$username"
            -p NAMESPACE="$namespace"
            -p IMAGE_NAME="$image_name"
            -p OPENSHIFT_URL="$openshift_url"
            -p IMAGE_REPO="$image_repo"
            -p HUB_HOST="$hub_host"
        )
        if [[ -n $notebook_token ]]; then
            params+=(-p TOKEN="$notebook_token")
        fi

        oc process -f test_resources.yaml --local "${params[@]}" |
            "${create_resource_command[@]}"
        if [[ "$shorten_url" == "true" && -n "$tiny_url_api_token" ]]; then
	        python add_tiny_url.py "$tiny_url_api_token" "$url" "tinyurl.com" "$alias"
	        if [[ $? -eq 0 ]]; then
                echo "TinyURL created!"
            else
                echo "TinyURL creation failed!"
            fi
            sleep $rate_limit
        fi
    done
    wait  # Wait for the current batch to finish before starting the next
done

echo "All notebooks are starting. The total requests time is $SECONDS seconds."


