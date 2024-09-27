<details>
<summary>Usage</summary>

``` shell
# Launch step 1
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    -e task=launch_step_1 \
    -e aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    -e aws_secret_access_key=<AWS_SECRET_ACCESS_KEY> \
    -e parameters=<PARAMETERS> \
    -e name=<NAME> \
    -e role_arn=<ROLE_ARN> \  # Optional - default arn:aws:iam::515876044319:role/service-role/OmicsWorkflow-20240601210363
    -e output_uri=<OUTPUT_URI> \  # Optional - default s3://rti-nida-iomics-oa-healthomics-output/
    -e storage_capacity=<STORAGE_CAPACITY> \  # Optional - default 1000
    -e workflow_id=<WORKFLOW_ID> \  # Optional - default 3565858
    --rm rtibiocloud/wgs_qc_wf_tools:v1.0_1e4fbb0

# Launch step 2
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    -e task=launch_step_2 \
    -e aws_access_key_id=<AWS_ACCESS_KEY_ID> \
    -e aws_secret_access_key=<AWS_SECRET_ACCESS_KEY> \
    -e step_1_run_metadata_json=<STEP_1_RUN_METADATA_JSON> \
    -e step_2_config_output_dir=<STEP_2_CONFIG_OUTPUT_DIR> \
    -e role_arn=<ROLE_ARN> \  # Optional - default arn:aws:iam::515876044319:role/service-role/OmicsWorkflow-20240601210363
    -e output_uri=<OUTPUT_URI> \  # Optional - default s3://rti-nida-iomics-oa-healthomics-output/
    -e storage_capacity=<STORAGE_CAPACITY> \  # Optional - default 1000
    -e minimum_ancestry_sample_count=<MINIMUM_ANCESTRY_SAMPLE_COUNT> \  # Optional - default 50
    -e workflow_id=<WORKFLOW_ID> \  # Optional - default 5499609
    --rm rtibiocloud/wgs_qc_wf_tools:v1.0_1e4fbb0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/wgs_qc_wf_tools/v1.0

# Local build
docker build . -t wgs_qc_wf_tools/wgs_qc_wf_tools:v1.0

```
</details>

