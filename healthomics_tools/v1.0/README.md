# AWS HealthOmics Tools

## Overview

Tools for managing workflows and workflow runs in AWS HealthOmics.

## Create Workflow

### Command
``` sh
docker run -ti \
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=create_wf \
    -e aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    -e aws_secret_access_key=<AWS_SECRET_ACCESS_KEY> \
    -e aws_region_name=<AWS_REGION_NAME> \
    -e repo_dir=<REPO_DIR> \
    -e main=<MAIN_WDL> \
    -e parameter_template=<PARAMETER_TEMPLATE> \
    -e name=<NAME> \
    -e description=<DESCRIPTION> \
    -e engine=<ENGINE> \
    -e storage_capacity=<STORAGE_CAPACITY> \
    --rm <DOCKER_IMAGE>:<TAG>
```

### Parameters
| Parameter | Values | Default Value | Required |
| --------- | ------ | ------------- | -------- |
| aws_access_key_id | AWS access key ID |  | Yes |
| aws_secret_access_key | AWS secret access key |  | Yes |
| aws_region_name | AWS region |  | Yes |
| repo_dir | /path/to/repo |  | Yes |
| main | /path/to/wf_wdl |  | Yes |
| parameter_template | /path/to/parameter_json |  | Yes |
| name | string |  | Yes |
| description | string |  | Yes |
| engine | `WDL`, `NEXTFLOW`, `CWL`  | `WDL` | No |
| storage_capacity | `1-10000` (GB) | `2000` | No |


## Start Run

### Command
``` sh
docker run -ti \
    -v <HOST_DIR>:<CONTAINER_DIR> \
    -e task=start_run \
    -e charge_code=<CHARGE_CODE> \
    -e aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    -e aws_secret_access_key=<AWS_SECRET_ACCESS_KEY> \
    -e aws_region_name=<AWS_REGION_NAME> \
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
| Parameter | Values | Default Value | Required |
| --------- | ------ | ------------- | -------- |
| charge_code | RTI charge code |  | Yes |
| aws_access_key_id | AWS access key ID |  | Yes |
| aws_secret_access_key | AWS secret access key |  | Yes |
| aws_region_name | AWS region |  | Yes |
| workflow_id | string |  | Yes |
| parameters | /path/to/parameters_json |  | Yes |
| name | string |  | Yes |
| output_uri | /S3/path |  | Yes |
| run_metadata_output_dir | /path/to/run_metadata_output |  | Yes |
| workflow_type | `PRIVATE`, `READY2RUN` | `PRIVATE` | No |
| priority | `1-100000` | `100` | No |
| storage_type | `STATIC`, `DYNAMIC` | `STATIC` | No |
| storage_capacity | `1-10000` (GB) | `2000` | No |
| log_level | `OFF`, `FATAL`, `ERROR`, `ALL` | `ALL` | No |
| retention_mode | `RETAIN`, `REMOVE` | `RETAIN` | No |
