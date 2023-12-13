#!/bin/bash

oc_args=()
delete_all_tests=0

while getopts aw ch; do
    case $ch in
        w)  oc_args+=( --wait=false )
            ;;

        a)  delete_all_tests=1
            ;;

        *)  exit 2
            ;;
    esac
done
shift $(( OPTIND - 1 ))

if (( delete_all_tests )); then
    labelarg="ope-test-run"
elif (( $# == 0 )); then
    echo "No arguments supplied. Please provide the name of a test run to clean up." >&2
    exit 1
else
    labelarg="ope-test-run=$1"
fi

# Delete notebook
oc delete notebook -l "$labelarg" "${oc_args[@]}"
oc delete pvc -l "$labelarg" "${oc_args[@]}"

echo "Resources deletion completed."
