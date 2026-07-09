# AWS HealthOmics Tools

## Overview

Tools for managing workflows and workflow runs in AWS HealthOmics.

## Create Workflow

### Command
``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=create_wf \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
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
| storage_capacity | Default storage capacity in GB for workflow | integer | `1-10000` | `2000` | No |

### Notes
- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.

## Create Workflow Version

### Command
``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=create_wf \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
    -e repo_dir="<REPO_DIR>" \
    -e workflow_id="<WORKFLOW_ID>"
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
| storage_capacity | Default storage capacity in GB for workflow | integer | `1-10000` | `2000` | No |

### Notes
- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.


## Start Run

### Command
``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=start_run \
    -e charge_code="<CHARGE_CODE>" \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
    -e workflow_id="<WORKFLOW_ID>" \
    -e workflow_version_name="<WORKFLOW_VERSION_NAME>"
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
| name | Name to assign to run | string |  |  | Yes |
| cache_id | ID of cache to use for the run | string |  |  | No |
| cache_behavior | Cache behavior for the run | string | `CACHE_ON_FAILURE`, `CACHE_ALWAYS` |  | No |
| parameters | Path to JSON file containing run parameters | string |  |  | Yes |
| output_uri | S3 path for workflow output | string |  |  | Yes |
| run_metadata_output_dir | Directory to which run metadata will be output | string |  |  | Yes |
| workflow_type | Type of workflow to run | string |  `PRIVATE`, `READY2RUN` | `PRIVATE` | No |
| priority | Priority for run | integer | `1-100000` | `100` | No |
| storage_type | Storage type for run | string | `STATIC`, `DYNAMIC` | `STATIC` | No |
| storage_capacity | Storage capacity for run in GB if storage type = `STATIC` | integer | `1-10000` | `2000` | No |
| log_level | Log level for run | string | `OFF`, `FATAL`, `ERROR`, `ALL` | `ALL` | No |
| retention_mode | Retention mode for run | string | `RETAIN`, `REMOVE` | `RETAIN` | No |


## Cancel Runs

### Command
``` sh
docker run -ti \
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=cancel_runs \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
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
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
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
    -v "<HOST_DIR>":"<CONTAINER_DIR>" \
    -e task=retrieve_run_results \
    -e aws_profile="<AWS_PROFILE>" \
    -e AWS_SHARED_CREDENTIALS_FILE="<AWS_SHARED_CREDENTIAL_FILE>"
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

