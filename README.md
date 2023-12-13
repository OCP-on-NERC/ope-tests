# ope-tests

This repository contains a suite of tests designed to ensure the reliability of ope jupyter notebooks to run on NERC prod cluster.

## Scalability test

The [scalability test](scalability_test) is designed to evaluate the capability to handle a high volume of creation requests for Jupyter notebooks.

### Running the tests

To execute these tests:

1. Ensure you are logged in to your OpenShift account via the CLI.

2. Ensure you have set an appropriate default project. E.g:

    ```
    oc project ope-rhods-testing-1fef2f
    ```

3. Run the test script.

    Use the `create_notebooks.sh` script to run the test. You will need to specify the total number of notebooks to create, the batch size for concurrent requests, and your username. You can optionally provide a name for the test run with the `-n` option; if not, one will be generated for you.

    For example, to create 100 notebooks in batches of 10 at a time:

    ```
    ./create_notebook.sh 100 10 your_username
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

### Cleaning up

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
