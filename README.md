# ope-tests

This repository contains a suite of tests designed to ensure the reliability of ope jupyter notebooks to run on NERC prod cluster.

## Getting Started
- **Scalability Test**: Tests designed to evaluate the capability to handle a high volume of creation requests for Jupyter notebooks. To execute these tests:

    - **Login**: Ensure you are logged in to your OpenShift account via the CLI.
    - **Run the Test Script**: Use the provided script to initiate the tests. You need to specify the total number of notebooks to be created, the batch size for concurrent requests, and your username.
        - **Example**: Executing `./create_notebook.sh 100 10 <your_username>` will trigger the creation of 100 Jupyter notebooks, processing 10 requests concurrently.
    - **Cleanup resource**, Run `./cleanup.sh <num_notebooks>`.
