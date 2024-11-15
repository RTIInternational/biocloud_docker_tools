<details>
<summary>Usage</summary>

``` shell
# gvcf input
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/b38/ancestry_pipeline_args.json \
    -e wf_definition=t1dgrs2_pipeline_step_1 \
    --rm rtibiocloud/t1dgrs2_pipeline:v1.0_58cbe71

# Interactive
docker run -ti \
    -u docker \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    --entrypoint /bin/bash \
    -e wf_arguments=blah \
    -e wf_definition=blah \
    --rm docker.io/t1dgrs2_pipeline/t1dgrs2_pipeline:v1.0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/t1dgrs2_pipeline/v2.0

# Local build
docker build . -t t1dgrs2_pipeline/t1dgrs2_pipeline:v2.0

```
</details>

