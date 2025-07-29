#!/bin/bash

create_resource_command=(oc create -f -)
workbench=false
which_workbench=new
image_repo=""
pod_check=false
LOGFILE="gpu_check.log"

#function to create namespaces
create_ns() {
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
}

# function to create workbooks
create_wb() {
    random_id=$(openssl rand -hex 3)

    # give notebook within namespace a name
    notebook_name=${username,,}-${random_id}
    
    # add test run name of not given
    if [[ -z $test_run_name ]]; then
        test_run_name="$(mktemp -u kueue-test-"$username"-XXXXXX)"
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

    if [[ -n $image_repo ]]; then
        params+=(-p IMAGE_REPO=$image_repo)
    fi

    echo "creating workbench for project ${namespace}"

    oc process -f test_resources.yaml --local "${params[@]}" | "${create_resource_command[@]}"
    
    echo " "

    # monitor output of nvidia-smi in pods
    if [[ "$pod_check" == true ]]; then
        pod_check;
    fi
}

# function to check what nvidia-smi outputs in pod
pod_check() {
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
}


while getopts t:r:w:p: ch; do
   case $ch in
       t) test_run_name=$OPTARG
           ;;
       #if registry is different than rhods-ods-applications
       r) image_repo=$OPTARG
            ;;
       w) which_workbench=$OPTARG
          workbench=true
            ;;
       p) pod_check=$OPTARG
            ;;
       *)  exit 2
           ;;
   esac
done

shift $(( OPTIND - 1 ))

# if workbench supplied is old, then num of namespaces cannot be supplied
if [[ "$workbench" == "true" ]]; then
    if [[ "$which_workbench" == "old" ]]; then
        if [[ $# -ne 3 ]]; then
            echo "Usage: $0 [-t <test-run-name>] [-r <image-registry>] [-w <workbenches: old|new>] [-p <pod_check: true|false>] <username> <image_name> <openshift_url>" >&2
            exit 1
        fi
    else
        if [[ $# -ne 4 ]]; then
            echo "Usage: $0 [-t <test-run-name>] [-r <image-registry>] [-w <workbenches: old|new>] [-p <pod_check: true|false>] <num_namespaces> <username> <image_name> <openshift_url>" >&2
            exit 1
        fi
    fi
else
    if [[ $# -ne 3 ]]; then
      echo "Usage: $0 [-t <test-run-name>] [-r <image-registry>] <num_namespaces> <username> <openshift_url>" >&2
      exit 1
    fi
fi


if [[ "$workbench" == "false" ]]; then
    # Number of namespaces to create
    num_namespaces=$1

    # Username
    username=$2

    # openshift url
    openshift_url=$3

else
    if [[ "$which_workbench" == "old" ]]; then
        # Username
        username=$1
        
        #image name
        image_name=$2

        # openshift url
        openshift_url=$3
    else
        # Number of namespaces to create
        num_namespaces=$1

        # Username
        username=$2

        #image name
        image_name=$3

        # openshift url
        openshift_url=$4

    fi
fi


# split openshift url to provide as parameters
host="${openshift_url%/projects*}"        # get everything before projects
hub_host=$host

# cases where we are just creating namespaces, or creating new namespaces for each workbench
if [[ "$which_workbench" == "new" || "$workbench" == "false" ]]; then

  #create requested amount of namespaces
  for ((i=0; i<num_namespaces; i++)); do 
    create_ns;
  done

    echo "namespaces created"
    echo " "
fi


if [[ "$workbench" == true ]]; then
    #needs time to have all the projects be visible before creating workbenches
    sleep 20
    
    namespaces=$(oc get projects -l test_name=kueue_test -o jsonpath='{.items[*].metadata.name}')

    if [[ -z $namespaces ]]; then
        echo "must create namespaces before workbenches"
        exit 0
    fi

    for namespace in $namespaces; do
        oc project ${namespace}

        #create workbook for each namespace
        create_wb;

    done

    echo "workbenches created"
fi