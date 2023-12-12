#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <num_notebooks> <batch_size> <username>"
    exit 1
fi

# Number of notebbooks to create
num_notebooks=$1
# Number of requests to make concurrently
batch_size=$2
username=$3
SECONDS=0

create_resources() {
    notebook_name=$1
    # Create service account
    sed "s/ope-placeholder/$notebook_name/g" sa_template.yaml | oc apply -f -

    # Create pvc
    sed "s/ope-placeholder/$notebook_name/g" pvc_template.yaml | oc apply -f -

    # Create notebook
    sed -e "s/ope-placeholder/$notebook_name/g" -e "s/your_username/$username/g" notebook_template.yaml | oc apply -f -
}

for ((i=0; i<$num_notebooks; i+=batch_size)); do
    for ((j=0; j<$batch_size && (i+j)<$num_notebooks; j++)); do
        notebook_name="ope-scalability-$((i+j))"
        create_resources "$notebook_name" &
    done
    # Wait for the current batch to finish before starting the next
    wait
done

echo "All notebooks are starting. The total requests time is $SECONDS seconds."
