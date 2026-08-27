# AWS HealthOmics Tools

## Overview

Tools for managing workflows and workflow runs in AWS HealthOmics.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Create Workflow](#create-workflow)
- [Create Workflow Version](#create-workflow-version)
- [Start Run](#start-run)
- [Cancel Runs](#cancel-runs)
- [Delete Runs](#delete-runs)
- [Retrieve Run Results](#retrieve-run-results)

## Prerequisites

- All host paths referenced by parameters (`repo_dir`, `main`, `readme`, `parameters`, `run_metadata_output_dir`, `target_dir`, etc.) must resolve to paths *inside* the container. Mount the relevant host directory with `-v "<HOST_DIR>":"<CONTAINER_DIR>"` and pass container-relative paths for these parameters.
- `AWS_SHARED_CREDENTIALS_FILE` must point to a credentials file path that is reachable inside the container (i.e. under the mounted `<CONTAINER_DIR>`), and `aws_profile` must reference a profile defined in that file.
- For `start_run`, the IAM role used (`role_arn`, or the default `arn:aws:iam::<account_id>:role/OmicsWorkflow` if not specified) must already exist and have permission to access AWS HealthOmics, S3, CloudWatch Logs, and EC2 as described in the [AWS HealthOmics service role documentation](https://docs.aws.amazon.com/omics/latest/dev/setting-up.html).

## Create Workflow

### Command

``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=create_wf \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e repo_dir="<REPO_DIR>" \
    -e main="<MAIN_WDL>" \
    -e name="<NAME>" \
    -e description="<DESCRIPTION>" \
    -e readme="<README>" \
    -e engine="<ENGINE>" \
    -e storage_capacity="<STORAGE_CAPACITY>" \
    --rm "<DOCKER_IMAGE>":"<TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string  |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| repo_dir | Base path for Git repository containing workflow definition | string |  |  | Yes |
| main | Path to main workflow definition file | string |  |  | Yes |
| name | Name to assign to workflow | string |  |  | Yes |
| description | Description of workflow | string |  |  | Yes |
| readme | Path to README file for wf | string |  |  | Yes |
| engine | Engine to use for workflow | string | `WDL`, `NEXTFLOW`, `CWL`  | `WDL` | No |
| storage_capacity | Default storage capacity in GB for workflow | integer | See note [^1] | `2000` | No |

### Notes

- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.

## Create Workflow Version

### Command

``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=create_wf_version \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e repo_dir="<REPO_DIR>" \
    -e workflow_id="<WORKFLOW_ID>" \
    -e main="<MAIN_WDL>" \
    -e name="<NAME>" \
    -e description="<DESCRIPTION>" \
    -e readme="<README>" \
    -e engine="<ENGINE>" \
    -e storage_capacity="<STORAGE_CAPACITY>" \
    --rm "<DOCKER_IMAGE>":"<TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string  |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| repo_dir | Base path for Git repository containing workflow definition | string |  |  | Yes |
| main | Path to main workflow definition file | string |  |  | Yes |
| workflow_id | ID of the existing workflow for which a new version will be created | string |  |  | Yes |
| name | Name to assign to workflow | string |  |  | Yes |
| description | Description of workflow | string |  |  | Yes |
| readme | Path to README file for wf | string |  |  | Yes |
| engine | Engine to use for workflow | string | `WDL`, `NEXTFLOW`, `CWL`  | `WDL` | No |
| storage_capacity | Default storage capacity in GB for workflow | integer | See note [^1] | `2000` | No |

### Notes

- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.


## Start Run

### Command

``` sh
docker run -ti \
    -u $(id -u):$(id -g) \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=start_run \
    -e charge_code="<CHARGE_CODE>" \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e workflow_id="<WORKFLOW_ID>" \
    -e workflow_version_name="<WORKFLOW_VERSION_NAME>" \
    -e workflow_owner_id="<WORKFLOW_OWNER_ID>" \
    -e run_group_id="<RUN_GROUP_ID>" \
    -e run_id="<RUN_ID>" \
    -e role_arn="<ROLE_ARN>" \
    -e name="<NAME>" \
    -e cache_id="<CACHE_ID>" \
    -e cache_behavior="<CACHE_BEHAVIOR>" \
    -e parameters="<PARAMETERS>" \
    -e output_uri="<OUTPUT_URI>" \
    -e run_metadata_output_dir="<RUN_METADATA_OUTPUT_DIR>" \
    -e workflow_type="<WORKFLOW_TYPE>" \
    -e priority="<PRIORITY>" \
    -e storage_type="<STORAGE_TYPE>" \
    -e storage_capacity="<STORAGE_CAPACITY>" \
    -e log_level="<LOG_LEVEL>" \
    -e retention_mode="<RETENTION_MODE>" \
    -e networking_mode="<NETWORKING_MODE>" \
    -e scratch_storage_mode="<SCRATCH_STORAGE_MODE>" \
    -e configuration_name="<CONFIGURATION_NAME>" \
    --rm "<DOCKER_IMAGE:TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string  |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| charge_code | RTI charge code | string |  |  | Yes |
| workflow_id | HealthOmics ID of workflow to run | string |  |  | Yes |
| workflow_version_name | Name of workflow version to run | String |  |  | No |
| workflow_owner_id | 12-digit account ID of the workflow owner; only required to run a workflow shared from another account | string |  |  | No |
| run_group_id | ID of the run group to associate with the run, used to cap compute resources/concurrency | string |  |  | No |
| run_id | ID of an existing run to duplicate | string |  |  | No |
| role_arn | Service role ARN for the run; defaults to `arn:aws:iam::<account_id>:role/OmicsWorkflow` for the caller's account | string |  |  | No |
| name | Name to assign to run | string |  |  | Yes |
| cache_id | ID of cache to use for the run | string |  |  | No |
| cache_behavior | Cache behavior for the run | string | `CACHE_ON_FAILURE`, `CACHE_ALWAYS` |  | No |
| parameters | Path to JSON file containing run parameters | string |  |  | Yes |
| output_uri | S3 path for workflow output | string |  |  | Yes |
| run_metadata_output_dir | Directory to which run metadata will be output | string |  |  | Yes |
| workflow_type | Type of workflow to run | string |  `PRIVATE`, `READY2RUN` | `PRIVATE` | No |
| priority | Priority for run | integer | See note [^1] | `100` | No |
| storage_type | Storage type for run | string | `STATIC`, `DYNAMIC` | `STATIC` | No |
| storage_capacity | Storage capacity for run in GB if storage type = `STATIC` | integer | See note [^1] | `2000` | No |
| log_level | Log level for run | string | `OFF`, `FATAL`, `ERROR`, `ALL` | `ALL` | No |
| retention_mode | Retention mode for run | string | `RETAIN`, `REMOVE` | `RETAIN` | No |
| networking_mode | Networking mode for the run | string | `RESTRICTED`, `VPC` | Unset (AWS defaults to `RESTRICTED`) | No |
| scratch_storage_mode | Scratch storage mode for the run (ephemeral storage mounted at `/tmp`); applies only to CPU tasks | string | `LOCAL`, `SHARED` | Unset (AWS defaults to `SHARED`) | No |
| configuration_name | Configuration name to use for the workflow run | string |  |  | No |

[^1]: This range is enforced by the AWS HealthOmics API, not by the wrapper scripts themselves; the scripts only validate that the value is an integer.

### Notes

- A metadata JSON file for the run is written to `run_metadata_output_dir/<name>_metadata.json`.


## Cancel Runs

### Command

``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=cancel_runs \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e run_ids="<RUN_IDS>" \
    -e run_statuses="<RUN_STATUSES>" \
    -e delete_run_data="<DELETE_RUN_DATA>" \
    --rm "<DOCKER_IMAGE>":"<TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| run_ids | Run IDs of runs to cancel (separated by commas) | string |  |  | No |
| run_statuses | Run statuses of runs to cancel (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING` |  | No |
| delete_run_data | Whether to delete run data after cancelling runs | boolean | `TRUE`, `FALSE` | `FALSE` | No |


## Delete Runs

### Command

``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=delete_runs \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e run_ids="<RUN_IDS>" \
    -e run_statuses="<RUN_STATUSES>" \
    --rm "<DOCKER_IMAGE>":"<TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| run_ids | Run IDs of runs to delete (separated by commas) | string |  |  | No |
| run_statuses | Run statuses of runs to delete (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING`, `COMPLETED`, `DELETED`, `CANCELLED`, `FAILED` |  | No |


## Retrieve Run Results

### Command

``` sh
docker run -ti \
    -u $(id -u):$(id -g) \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=retrieve_run_results \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>" \
    -e run_id="<RUN_ID>" \
    -e target_dir="<TARGET_DIR>" \
    --rm "<DOCKER_IMAGE>":"<TAG>"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string |  |  | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string  |  |  | Yes |
| run_id | ID of run for which to retrieve results | string |  |  | Yes |
| target_dir | Target directory for run results | string |  |  | Yes |

