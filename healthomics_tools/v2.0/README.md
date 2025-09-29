# AWS HealthOmics Tools

## Overview

Tools for managing workflows and workflow runs in AWS HealthOmics.

## Create Workflow

### Command
``` sh
docker run -ti \
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=create_wf \
    -e aws_profile=<AWS_PROFILE> \
    -e repo_dir=<REPO_DIR> \
    -e main=<MAIN_WDL> \
    -e name=<NAME> \
    -e description=<DESCRIPTION> \
    -e readme=<README> \
    -e engine=<ENGINE> \
    -e storage_capacity=<STORAGE_CAPACITY> \
    --rm <DOCKER_IMAGE>:<TAG>
```

### Parameters
| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string  |  |  | Yes |
| repo_dir | Base path for Git repository containing workflow definition | string |  |  | Yes |
| main | Path to main workflow definition file | string |  |  | Yes |
| name | Name to assign to workflow | string |  |  | Yes |
| description | Description of workflow | string |  |  | Yes |
| engine | Engine to use for workflow | string | `WDL`, `NEXTFLOW`, `CWL`  | `WDL` | No |
| storage_capacity | Default storage capacity in GB for workflow | integer | `1-10000` | `2000` | No |

### Notes
- For the WDL workflow file specified with `main`, there must be accompanying dependencies and parameters json files with specific naming conventions. For example, if the WDL file specified with `main` is `example_wf.wdl`, there must be a `example_wf_dependencies.json` and `example_wf_parameters.json` file in the same directory.


## Start Run

### Command
``` sh
docker run -ti \
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=start_run \
    -e charge_code=<CHARGE_CODE> \
    -e aws_profile=<AWS_PROFILE> \
    -e workflow_id=<WORKFLOW_ID> \
    -e parameters=<PARAMETERS> \
    -e name=<NAME> \
    -e output_uri=<OUTPUT_URI> \
    -e run_metadata_output_dir=<RUN_METADATA_OUTPUT_DIR> \
    -e workflow_type=<WORKFLOW_TYPE> \
    -e priority=<PRIORITY> \
    -e storage_type=<STORAGE_TYPE> \
    -e storage_capacity=<STORAGE_CAPACITY> \
    -e log_level=<LOG_LEVEL> \
    -e retention_mode=<RETENTION_MODE> \
    --rm <DOCKER_IMAGE>:<TAG>
```

### Parameters
| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string  |  |  | Yes |
| charge_code | RTI charge code | string |  |  | Yes |
| workflow_id | HealthOmics ID of workflow to run | string |  |  | Yes |
| parameters | Path to JSON file containing run parameters | string |  |  | Yes |
| name | Name to assign to workflow | string |  |  | Yes |
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
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=cancel_runs \
    -e aws_profile=<AWS_PROFILE> \
    -e run_ids=<RUN_IDS> \
    -e run_statuses=<RUN_STATUSES> \
    -e delete_run_data=<DELETE_RUN_DATA> \
    --rm <DOCKER_IMAGE>:<TAG>
```

### Parameters
| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string |  |  | Yes |
| run_ids | Run IDs of runs to cancel (separated by commas) | string |  |  | No |
| run_statuses | Run statuses of runs to cancel (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING` |  | No |
| delete_run_data | Whether to delete run data after cancelling runs | boolean | `TRUE`, `FALSE` | `FALSE` | No |


## Delete Runs

### Command
``` sh
docker run -ti \
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=cancel_all_runs \
    -e aws_profile=<AWS_PROFILE> \
    -e run_status=<"PENDING|STARTING|RUNNING|STOPPING|COMPLETED|DELETED|CANCELLED|FAILED"> \
    -e delete_run_data=<"TRUE|FALSE"> \
    -e run_output_dir=<RUN_OUTPUT_DIR> \
    --rm <DOCKER_IMAGE>:<TAG>
```

### Parameters
| Parameter | Description | Type | Choices | Default Value | Required |
| --------- | ------ | ---- | ------- | ------------- | -------- |
| aws_profile | AWS profile to use for credentials | string |  |  | Yes |
| run_ids | Run IDs of runs to delete (separated by commas) | string |  |  | No |
| run_statuses | Run statuses of runs to delete (separated by commas) | string | `PENDING`, `STARTING`, `RUNNING`, `STOPPING`, `COMPLETED`, `DELETED`, `CANCELLED`, `FAILED` |  | No |



