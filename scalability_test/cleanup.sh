#!/bin/bash

if [ $# -eq 0 ]
then
    echo "No arguments supplied. Please provide the number of notebooks to clean up."
    exit 1
fi

for i in $(seq 0 $(( $1 - 1 ))); do
  notebook_name="ope-scalability-$i"

  # Delete notebook
  oc delete notebook $notebook_name

  # # Delete PVC
  oc delete pvc $notebook_name

  # Delete Service Account
  oc delete serviceaccount $notebook_name

done

echo "Resources deletion completed."
