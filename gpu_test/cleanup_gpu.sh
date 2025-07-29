#!/bin/bash

# removes every project whose name starts with “kueue‑test‑”.
pattern="^kueue-test-"
d=0

while getopts d ch; do
   case $ch in
       d)  delete=1
            ;;
       *)  exit 2
           ;;
   esac
done

# list projects, filter by prefix, then delete each
for proj in $(oc get projects -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep "$pattern"); do

    echo "deleting notebook + pvc"
    oc -n "$proj" delete notebook --all --ignore-not-found --wait=true || true
    oc -n "$proj" delete pvc --all --ignore-not-found --wait=true || true

    echo "Deleting $proj"
    oc delete project "$proj" --as system:admin
    echo " "
done

if ((delete)) && [[ -f "gpu_check.log" ]]; then
    echo "Deleting log file"
    rm gpu_check.log
fi