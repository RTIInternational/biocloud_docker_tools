# AWS HealthOmics Tools

## Overview

Tools for managing workflows and workflow runs in AWS HealthOmics.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Create Workflow](#create-workflow)
- [Create Workflow Version](#create-workflow-version)
- [Create Run Cache](#create-run-cache)
- [Start Run](#start-run)
- [Cancel Runs](#cancel-runs)
- [Delete Runs](#delete-runs)
- [Retrieve Run Results](#retrieve-run-results)

## Prerequisites

- All host paths referenced by parameters (`repo_dir`, `main`, `readme`, `parameters`, `run_metadata_output_dir`, `target_dir`, etc.) must resolve to paths *inside* the container. Mount the relevant host directory to the identical path in the container (e.g. `-v "$REPO_DIR":"$REPO_DIR"`) so the same path works on both sides.
- `AWS_SHARED_CREDENTIALS_FILE` must point to a credentials file path that is reachable inside the container (i.e. under a mounted directory), and `aws_profile` must reference a profile defined in that file.
- For `start_run`, the IAM role used (`role_arn`, or the default `arn:aws:iam::<account_id>:role/OmicsWorkflow` if not specified) must already exist and have permission to access AWS HealthOmics, S3, CloudWatch Logs, and EC2 as described in the [AWS HealthOmics service role documentation](https://docs.aws.amazon.com/omics/latest/dev/setting-up.html).

## Create Workflow

### Command

``` sh
# Define variables
REPO_DIR=/path/to/repo_dir
AWS_CREDENTIALS_DIR=/path/to/.aws
AWS_PROFILE=aws_profile
MAIN_WDL=$REPO_DIR/path/to/main.wdl
NAME=workflow_name
DESCRIPTION="Workflow description"
README_PATH=$REPO_DIR/path/to/README.md
ENGINE=WDL
STORAGE_CAPACITY=2000
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Create workflow
docker run -ti \
    -v "$REPO_DIR":"$REPO_DIR" \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=create_wf \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e repo_dir="$REPO_DIR" \
    -e main="$MAIN_WDL" \
    -e name="$NAME" \
    -e description="$DESCRIPTION" \
    -e readme="$README_PATH" \
    -e engine="$ENGINE" \
    -e storage_capacity="$STORAGE_CAPACITY" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| repo_dir | Base path for Git repository containing workflow definition | string | | | Yes |
| main | Path to main workflow definition file | string | | | Yes |
| name | Name to assign to workflow | string | | | Yes |
| description | Description of workflow | string | | | Yes |
| readme | Path to README file for wf | string | | | Yes |
| engine | Engine to use for workflow | string | `WDL`, `NEXTFLOW`, `CWL` | `WDL` | No |
| storage_capacity | Default storage capacity in GB for workflow | integer | See note [^1] | `2000` | No |

### Notes

- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.

## Create Workflow Version

### Command

``` sh
# Define variables
REPO_DIR=/path/to/repo_dir
AWS_CREDENTIALS_DIR=/path/to/.aws
AWS_PROFILE=aws_profile
WORKFLOW_ID=workflow_id
MAIN_WDL=$REPO_DIR/path/to/main.wdl
NAME=workflow_name
DESCRIPTION="Workflow description"
README_PATH=$REPO_DIR/path/to/README.md
ENGINE=WDL
STORAGE_CAPACITY=2000
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Create workflow version
docker run -ti \
    -v "$REPO_DIR":"$REPO_DIR" \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=create_wf_version \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e repo_dir="$REPO_DIR" \
    -e workflow_id="$WORKFLOW_ID" \
    -e main="$MAIN_WDL" \
    -e name="$NAME" \
    -e description="$DESCRIPTION" \
    -e readme="$README_PATH" \
    -e engine="$ENGINE" \
    -e storage_capacity="$STORAGE_CAPACITY" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| repo_dir | Base path for Git repository containing workflow definition | string | | | Yes |
| main | Path to main workflow definition file | string | | | Yes |
| workflow_id | ID of the existing workflow for which a new version will be created | string | | | Yes |
| name | Name to assign to workflow | string | | | Yes |
| description | Description of workflow | string | | | Yes |
| readme | Path to README file for wf | string | | | Yes |
| engine | Engine to use for workflow | string | `WDL`, `NEXTFLOW`, `CWL` | `WDL` | No |
| storage_capacity | Default storage capacity in GB for workflow | integer | See note [^1] | `2000` | No |

### Notes

- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.

## Create Run Cache

### Command

``` sh
# Define variables
AWS_CREDENTIALS_DIR=/path/to/.aws
CHARGE_CODE=charge_code
AWS_PROFILE=aws_profile
CACHE_S3_LOCATION=s3://bucket/path/for/cache
NAME=""
DESCRIPTION=""
CACHE_BEHAVIOR=""
CACHE_BUCKET_OWNER_ID=""
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Create run cache
docker run -ti \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=create_run_cache \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e charge_code="$CHARGE_CODE" \
    -e cache_s3_location="$CACHE_S3_LOCATION" \
    -e name="$NAME" \
    -e description="$DESCRIPTION" \
    -e cache_behavior="$CACHE_BEHAVIOR" \
    -e cache_bucket_owner_id="$CACHE_BUCKET_OWNER_ID" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| charge_code | RTI charge code | string | | | Yes |
| cache_s3_location | S3 location for storing cached task outputs; must be immediately accessible (not archived) | string | | | Yes |
| name | Name to assign to the run cache | string | | | No |
| description | Description of the run cache | string | | | No |
| cache_behavior | Default cache behavior for runs that use this cache | string | `CACHE_ON_FAILURE`, `CACHE_ALWAYS` | `CACHE_ON_FAILURE` | No |
| cache_bucket_owner_id | AWS account ID of the expected owner of the S3 bucket for the run cache | string | | | No |

### Notes

- The created run cache's `id`, `arn`, and `status` are printed to stdout.
- Pass the resulting cache ID to `start_run`'s `cache_id` parameter to use this cache for a run.

## Start Run

### Command

``` sh
# Define variables
DATA_DIR=/path/to/data/dir
AWS_CREDENTIALS_DIR=/path/to/.aws
CHARGE_CODE=charge_code
AWS_PROFILE=aws_profile
WORKFLOW_ID=workflow_id
WORKFLOW_VERSION_NAME=""
WORKFLOW_OWNER_ID=""
RUN_GROUP_ID=""
RUN_ID=""
ROLE_ARN=""
NAME=run_name
CACHE_ID=""
CACHE_BEHAVIOR=""
JSON_INPUTS_PATH=$DATA_DIR/path/to/json/inputs
OUTPUT_URI=/s3/path/for/workflow/output
RUN_METADATA_OUTPUT_DIR=$DATA_DIR/path/to/run_metadata_output_dir
WORKFLOW_TYPE=PRIVATE
PRIORITY=100
STORAGE_TYPE=STATIC
STORAGE_CAPACITY=2000
LOG_LEVEL=ALL
RETENTION_MODE=RETAIN
NETWORKING_MODE=""
SCRATCH_STORAGE_MODE=""
CONFIGURATION_NAME=""
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Start run
docker run -ti \
    -u $(id -u):$(id -g) \
    -v "$DATA_DIR":"$DATA_DIR" \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=start_run \
    -e charge_code="$CHARGE_CODE" \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e workflow_id="$WORKFLOW_ID" \
    -e workflow_version_name="$WORKFLOW_VERSION_NAME" \
    -e workflow_owner_id="$WORKFLOW_OWNER_ID" \
    -e run_group_id="$RUN_GROUP_ID" \
    -e run_id="$RUN_ID" \
    -e role_arn="$ROLE_ARN" \
    -e name="$NAME" \
    -e cache_id="$CACHE_ID" \
    -e cache_behavior="$CACHE_BEHAVIOR" \
    -e parameters="$JSON_INPUTS_PATH" \
    -e output_uri="$OUTPUT_URI" \
    -e run_metadata_output_dir="$RUN_METADATA_OUTPUT_DIR" \
    -e workflow_type="$WORKFLOW_TYPE" \
    -e priority="$PRIORITY" \
    -e storage_type="$STORAGE_TYPE" \
    -e storage_capacity="$STORAGE_CAPACITY" \
    -e log_level="$LOG_LEVEL" \
    -e retention_mode="$RETENTION_MODE" \
    -e networking_mode="$NETWORKING_MODE" \
    -e scratch_storage_mode="$SCRATCH_STORAGE_MODE" \
    -e configuration_name="$CONFIGURATION_NAME" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| charge_code | RTI charge code | string | | | Yes |
| workflow_id | HealthOmics ID of workflow to run | string | | | Yes |
| workflow_version_name | Name of workflow version to run | String | | | No |
| workflow_owner_id | 12-digit account ID of the workflow owner; only required to run a workflow shared from another account | string | | | No |
| run_group_id | ID of the run group to associate with the run, used to cap compute resources/concurrency | string | | | No |
| run_id | ID of an existing run to duplicate | string | | | No |
| role_arn | Service role ARN for the run; defaults to `arn:aws:iam::<account_id>:role/OmicsWorkflow` for the caller's account | string | | | No |
| name | Name to assign to run | string | | | Yes |
| cache_id | ID of cache to use for the run | string | | | No |
| cache_behavior | Cache behavior for the run | string | `CACHE_ON_FAILURE`, `CACHE_ALWAYS` | | No |
| parameters | Path to JSON file containing run parameters | string | | | Yes |
| output_uri | S3 path for workflow output | string | | | Yes |
| run_metadata_output_dir | Directory to which run metadata will be output | string | | | Yes |
| workflow_type | Type of workflow to run | string | `PRIVATE`, `READY2RUN` | `PRIVATE` | No |
| priority | Priority for run | integer | See note [^1] | `100` | No |
| storage_type | Storage type for run | string | `STATIC`, `DYNAMIC` | `STATIC` | No |
| storage_capacity | Storage capacity for run in GB if storage type = `STATIC` | integer | See note [^1] | `2000` | No |
| log_level | Log level for run | string | `OFF`, `FATAL`, `ERROR`, `ALL` | `ALL` | No |
| retention_mode | Retention mode for run | string | `RETAIN`, `REMOVE` | `RETAIN` | No |
| networking_mode | Networking mode for the run | string | `RESTRICTED`, `VPC` | Unset (AWS defaults to `RESTRICTED`) | No |
| scratch_storage_mode | Scratch storage mode for the run (ephemeral storage mounted at `/tmp`); applies only to CPU tasks | string | `LOCAL`, `SHARED` | Unset (AWS defaults to `SHARED`) | No |
| configuration_name | Configuration name to use for the workflow run | string | | | No |

[^1]: This range is enforced by the AWS HealthOmics API, not by the wrapper scripts themselves; the scripts only validate that the value is an integer.

### Notes

- A metadata JSON file for the run is written to `run_metadata_output_dir/<name>_metadata.json`.
- To use the `cache_id`/`cache_behavior` parameters, a run cache must already exist; create one first with [Create Run Cache](#create-run-cache) and pass its `id` as `cache_id`.

## Cancel Runs

### Command

``` sh
# Define variables
AWS_CREDENTIALS_DIR=/path/to/.aws
AWS_PROFILE=aws_profile
RUN_IDS=""
RUN_STATUSES=""
DELETE_RUN_DATA=FALSE
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Cancel runs
docker run -ti \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=cancel_runs \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e run_ids="$RUN_IDS" \
    -e run_statuses="$RUN_STATUSES" \
    -e delete_run_data="$DELETE_RUN_DATA" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| run_ids | Run IDs of runs to cancel (separated by commas) | string | | | No |
| run_statuses | Run statuses of runs to cancel (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING` | | No |
| delete_run_data | Whether to delete run data after cancelling runs | boolean | `TRUE`, `FALSE` | `FALSE` | No |

## Delete Runs

### Command

``` sh
# Define variables
AWS_CREDENTIALS_DIR=/path/to/.aws
AWS_PROFILE=aws_profile
RUN_IDS=""
RUN_STATUSES=""
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Delete runs
docker run -ti \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=delete_runs \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e run_ids="$RUN_IDS" \
    -e run_statuses="$RUN_STATUSES" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| run_ids | Run IDs of runs to delete (separated by commas) | string | | | No |
| run_statuses | Run statuses of runs to delete (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING`, `COMPLETED`, `DELETED`, `CANCELLED`, `FAILED` | | No |

## Retrieve Run Results

### Command

``` sh
# Define variables
DATA_DIR=/path/to/data/dir
AWS_CREDENTIALS_DIR=/path/to/.aws
AWS_PROFILE=aws_profile
RUN_ID=run_id
TARGET_DIR=$DATA_DIR/path/to/target_dir
DOCKER_IMAGE="<DOCKER_IMAGE>:<TAG>"

# Retrieve run results
docker run -ti \
    -u $(id -u):$(id -g) \
    -v "$DATA_DIR":"$DATA_DIR" \
    -v "$AWS_CREDENTIALS_DIR":"$AWS_CREDENTIALS_DIR" \
    -e task=retrieve_run_results \
    -e aws_profile="$AWS_PROFILE" \
    -e AWS_SHARED_CREDENTIALS_FILE="$AWS_CREDENTIALS_DIR/credentials" \
    -e run_id="$RUN_ID" \
    -e target_dir="$TARGET_DIR" \
    --rm "$DOCKER_IMAGE"
```

### Parameters

| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string | | | Yes |
| AWS_SHARED_CREDENTIALS_FILE | Path to AWS shared credential file | string | | | Yes |
| run_id | ID of run for which to retrieve results | string | | | Yes |
| target_dir | Target directory for run results | string | | | Yes |
