# ope-tests

This repository contains a suite of tests designed to ensure the reliability of ope jupyter notebooks to run on NERC prod cluster.

## Scalability test

The [scalability test](scalability_test) is designed to evaluate the capability to handle a high volume of creation requests for Jupyter notebooks.

### Running the tests

To execute these tests:

1. Ensure you are logged in to your OpenShift account via the CLI.

2. Ensure you are in the scalibility_test folder.

3. Ensure you have set an appropriate default project. E.g:

    ```
    oc project ope-rhods-testing-1fef2f
    ```

4. Run the test script.

    Use the `create_notebooks.sh` script to run the test. You will need to specify the total number of notebooks to create, the batch size for concurrent requests, your username, the image name, and the openshift url. The openshift url is the link from openshift AI dashboard. It should look like: https://rhods-dashboard-redhat-applications.apps.project-name.association.assoc.org/projects. You can optionally provide a name for the test run with the `-t` option; if not, one will be generated for you.

    For example, to create 100 notebooks in batches of 10 at a time:

    ```
    ./create_notebook.sh 100 10 your_username image_name openshift_url
    ```

    To launch notebooks with GPUs, use image `minimal-gpu:2023.1`; edit the test_resources.yaml:

    ```
    spec:
        affinity:
          nodeAffinity:
            preferredDuringSchedulingIgnoredDuringExecution:
              - preference:
                  matchExpressions:
                    - key: nvidia.com/gpu.present
                      operator: In
                      values:
                        - 'true'
                weight: 1
    ```

    Set the ${NOTEBOOK_NAME} container with gpu:

    ```
    - resources:
        limits:
          cpu: '1'
          memory: 2Gi
          nvidia.com/gpu: '1'
        requests:
          cpu: '1'
          memory: 2Gi
          nvidia.com/gpu: '1'
    ```

    Output will look something like:

    ```
    Starting test run ope-test-your_username-100-t4y5rb with 100 notebooks
    notebook.kubeflow.org/ope-test-your_username-100-t4y5rb-0 created
    persistentvolumeclaim/ope-test-your_username-100-t4y5rb-0 created
    .
    .
    .
    notebook.kubeflow.org/ope-test-your_username-100-t4y5rb-99 created
    persistentvolumeclaim/ope-test-your_username-100-t4y5rb-99 created
    All notebooks are starting. The total requests time is 10 seconds.
    ```

    To calculate the average notebooks startup time, run
    ```
    ./calculate_latency.sh <test_name> <namespace>
    ```

### Cleaning up the scalability tests

To remove the test artifacts associated with your test, run `cleanup.sh` with the name of your test run. For example, to clean up the test run shown in the previous example:

```
./cleanup.sh ope-test-your_username-100-t4y5rb
```

Output will look something like:

```
notebook.kubeflow.org "ope-test-your_username-100-t4y5rb-0" deleted
.
.
.
notebook.kubeflow.org "ope-test-your_username-100-t4y5rb-99" deleted
persistentvolumeclaim "ope-test-your_username-100-t4y5rb-0" deleted
.
.
.
persistentvolumeclaim "ope-test-your_username-100-t4y5rb-99" deleted
Resources deletion completed.
```

To remove all test artifacts (associated with any test run), use the `-a` option:

```
./cleanup.sh -a
```

## GPU test

The [gpu test](gpu_test) is designed to test how GPUs are scheduled across different projects.

### Running the tests

To execute these tests:

1. Ensure you are logged in to your OpenShift account via the CLI.

2. Ensure you are in the gpu_test folder.

3. Run the test script. Use the `create_gpu.sh` to run the script. You will need to specify the total number of projects to create (which corresponds to the amount of students), your username, and the openshift url. The openshift url is the link from openshift AI dashboard. It should look like: https://rhods-dashboard-redhat-applications.apps.project-name.association.assoc.org/projects. 

If you want workbenches that use GPUs on each project, specify `-w` old | new, which specifies whether you want them on old, previously created namespaces, or if you want to create new namepaces with workbenches on them. Another parameter needed is the parameter image_name, so you can specify what kind of workbench you want. 

If you want to see the output of nvidia-smi in those pods, to get see what gpus are running in the pod, you can specify `-p` true. You can optionally provide a name for the test run with the `-t` option; if not, one will be generated for you.

For example, to create 3 namespaces:
```
./create_gpu.test 3 your_username openshift_url
```

And to create workbenches on the namespaces you previously created, as well as get the logs for the gpus running on those projects:

```
./create_gpu.test -w old -p true your_username image_name openshift_url
```
Note that here you CANNOT provide the amount of namespaces and that you provide an image name.


But if you want to create 3 new namespaces, with a workbench on each new namespace, as well as get the logs for the gpus running on those projects :

```
./create_gpu.test -w new -p true 3 your_username image_name openshift_url
```
Note that here you CAN provide the amount of namespaces and that you provide an image name.


The output will look something like this if you create just namespaces:
```
.ocp-test.nerc.mghpcc.org/projects/ope-test?section=workbenches
creating new namespace...
Now using project "kueue-test-6b672f" on server "https://api.ocp-test.nerc.mghpcc.org:6443".
.
.
.
labeling namespace...
namespace/kueue-test-6b672f labeled
adding edit permissions...
clusterrole.rbac.authorization.k8s.io/edit added: "memalhot"
.
.
.
labeling namespace...
namespace/kueue-test-da4a7d labeled
adding edit permissions...
clusterrole.rbac.authorization.k8s.io/edit added: "memalhot"
. 
.
.
labeling namespace...
namespace/kueue-test-da4a7d labeled
adding edit permissions...
clusterrole.rbac.authorization.k8s.io/edit added: "memalhot"
 
namespaces created
```
And if you run with the -w flag set to true, it will have the added output of:

```
Already on project "kueue-test-76fe15" on server "https://api.ocp-test.nerc.mghpcc.org:6443".
creating workbench for project kueue-test-76fe15
notebook.kubeflow.org/memalhot-865b57 created
persistentvolumeclaim/memalhot-865b57 created
 
Now using project "kueue-test-815b19" on server "https://api.ocp-test.nerc.mghpcc.org:6443".
creating workbench for project kueue-test-815b19
notebook.kubeflow.org/memalhot-c38fcd created
persistentvolumeclaim/memalhot-c38fcd created

Now using project "kueue-test-422cf3" on server "https://api.ocp-test.nerc.mghpcc.org:6443".
creating workbench for project kueue-test-815b19
notebook.kubeflow.org/memalhot-422cf3 created
persistentvolumeclaim/memalhot-422cf3 created

workbenches created
```

The log file will look something like this:
```
--- kueue-test-5e1c0a/memalhot-ef624c-0 ----
Defaulted container "memalhot-ef624c" out of: memalhot-ef624c, oauth-proxy
Thu Jul 24 20:27:31 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.124.06             Driver Version: 570.124.06     CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA H100 80GB HBM3          On  |   00000000:06:00.0 Off |                    0 |
| N/A   26C    P0             67W /  699W |       1MiB /  81559MiB |      0%      Default |
|                                         |                        |             Disabled |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
```

### Cleaning up the gpu tests
To remove the test artifacts associated with your test, just run `cleanup_gpu.sh`.

Like this:
```
./cleanup_gpu.sh
```

Output should look like:
```
Deleting kueue-test-76fe15
project.project.openshift.io "kueue-test-070a10" deleted
Deleting kueue-test-815b19
project.project.openshift.io "kueue-test-39880a" deleted
Deleting kueue-test-422cf3
project.project.openshift.io "kueue-test-bbd5ff" deleted
```

If you want to delete the log file as well, specify the -d flag:

Like this:
```
./cleanup_gpu.sh -d
```

Output should look like:
```
deleting notebook + pvc
notebook.kubeflow.org "memalhot-aa393e" deleted
persistentvolumeclaim "memalhot-aa393e" deleted
Deleting kueue-test-0583be
project.project.openshift.io "kueue-test-0583be" deleted
deleting notebook + pvc
notebook.kubeflow.org "memalhot-ba21cb" deleted
persistentvolumeclaim "memalhot-ba21cb" deleted
Deleting kueue-test-32bf5a
project.project.openshift.io "kueue-test-32bf5a" deleted

Deleting log file
```
