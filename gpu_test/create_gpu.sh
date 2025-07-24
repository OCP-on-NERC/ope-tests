#!/bin/bash

# ADD NEW LINE ADD NEW LINE ADD NEW LINE

create_resource_command=(oc create -f -)
notebook_token_enabled=false
workbench=false
image_repo=""
pod_check=false
LOGFILE="gpu_check.log"

while getopts t:e:r:w:p: ch; do
   case $ch in
       t)  test_run_name=$OPTARG
           ;;
       e)  notebook_token_enabled=$OPTARG
           ;;
       #if registry is different than rhods-ods-applications
       r) image_repo=$OPTARG
            ;;
       w) workbench=$OPTARG
            ;;
       p) pod_check=$OPTARG
            ;;
       *)  exit 2
           ;;
   esac
done

shift $(( OPTIND - 1 ))

if [[ $# -ne 4 ]]; then
   echo "Usage: $0 [-t <test-run-name>] [-e <enable_notebook_token: true|false>] [-r <image-registry>] [-w <workbenches: true|false>] [-p <pod_check: true|false>] <num_namespaces> <username> <image_name> <openshift_url>" >&2
   exit 1
fi

# Number of namespaces to create
num_namespaces=$1

# Username
username=$2

# Image to use
image_name=$3

# openshift url
openshift_url=$4

# split openshift url to provide as parameters
host="${openshift_url%/projects*}"        # get everything before projects
hub_host=$host


for (( i=0; i<num_namespaces; i++ )); do
    random_id=$(openssl rand -hex 3)

   # for naming namespace
   namespace=kueue-test-${random_id}

   # create namespace for each student and give permissions to create in namespace
   printf "creating new namespace...\n"
   oc new-project ${namespace} --display-name="${namespace}" --as system:admin
   printf "labeling namespace...\n"
   oc label namespace ${namespace} test_name=kueue_test --as system:admin
   printf "adding edit permissions...\n"
   oc adm policy add-role-to-user edit ${username} -n ${namespace} --as system:admin
   echo " "

done
echo "namespaces created"
echo " "

if [[ "$workbench" == true ]]; then
    #needs time to have all the projects be visible before creating workbenches
    if [ ${num_namespaces} -le 3 ]; then
        sleep 10
    else
        sleep 30
    fi

    for namespace in $(oc get projects -l test_name=kueue_test -o jsonpath='{.items[*].metadata.name}'); do

        oc project ${namespace}

        random_id=$(openssl rand -hex 3)

        # give notebook within namespace a name
        notebook_name=${username}-${random_id}
        
        # add test run name of not given
        if [[ -z $test_run_name ]]; then
            test_run_name="$(mktemp -u kueue-test-"$username"-XXXXXX)"
        fi

        notebook_token=""
        if [[ "$notebook_token_enabled" == "true" ]]; then
            notebook_token=$(openssl rand -hex 6)  # Generate a real token
        fi

        #create workbench within that namespace
        params=(
            -p NOTEBOOK_NAME="$notebook_name"
            -p TEST_RUN_NAME="$test_run_name"
            -p USERNAME="$username"
            -p NAMESPACE="$namespace"
            -p IMAGE_NAME="$image_name"
            -p OPENSHIFT_URL="$openshift_url"
            -p HUB_HOST="$hub_host"
        )
            
        if [[ -n $notebook_token ]]; then
            params+=(-p TOKEN="$notebook_token")
        fi

        if [[ -n $image_repo ]]; then
            params+=(-p IMAGE_REPO=$image_repo)
        fi

        echo "creating workbench for project ${namespace}"

        oc process -f kueue_resources.yaml --local "${params[@]}" | "${create_resource_command[@]}"
        
        echo " "

        # monitor output of nvidia-smi in pods
        if [[ "$pod_check" == true ]]; then
            sleep 5

            pod=$(oc get pod -n "$namespace" \
                -l notebook-name="$notebook_name" \
                -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
            
            oc wait -n "$namespace" --for=condition=Ready pod/"$pod" --timeout=360s || true

            if [[ -n "$pod" ]]; then
            {
                echo "---- $namespace/$pod ----"
                oc exec -n "$namespace" "$pod" -- nvidia-smi 2>&1 || echo "nvidia-smi not available"
                echo " "
            } >> "$LOGFILE"
            fi
        fi

    done

    echo "workbenches created"
fi