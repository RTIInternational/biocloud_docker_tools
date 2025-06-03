# Ancestry Pipeline

## Usage

### Command
``` bash
docker run -ti \
    -v <VOLUME_NAME>:<MOUNT_PATH> \
    -e wf_arguments=<WORKFLOW_ARGS_JSON> \
    -e wf_definition=<ENTRYPOINT> \
    --rm rtibiocloud/ancestry_pipeline:v1.0_cf38d38
```

### Parameters
| Parameter | Values | Default Value | Required |
| --------- | ------ | ------------- | -------- |
| VOLUME_NAME | Local volume to mount in Docker container |  | Yes |
| MOUNT_PATH | Path in Docker container to mount the local volume |  | Yes |
| WORKFLOW_ARGS_JSON | JSON file containing workflow arguments |  | Yes |
| ENTRYPOINT | ancestry_from_bfile, ancestry_from_bfiles, ancestry_from_gvcf, ancestry_from_gvcfs |  | Yes |


## Interactive Docker session
### Command
```bash
docker run -ti \
    -v <VOLUME_NAME>:<MOUNT_PATH> \
    --entrypoint bash \
    --rm rtibiocloud/ancestry_pipeline:v1.0_cf38d38
```
### Parameters
| Parameter | Values | Default Value | Required |
| --------- | ------ | ------------- | -------- |
| VOLUME_NAME | Local volume to mount in Docker container |  | Yes |
| MOUNT_PATH | Path in Docker container to mount the local volume |  | Yes |



## Build instructions

``` shell
cd biocloud_docker_tools/ancestry_pipeline/v1.0
docker build . -t ancestry_pipeline/ancestry_pipeline:v1.0
```

