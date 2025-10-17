<details>
<summary>Usage Examples</summary>

``` shell
# bfile input
docker run -ti \
    -v /shared/ngaddis:/shared/ngaddis \
    -e wf_arguments=/shared/ngaddis/data/temp/t1d/entrypoint_bfile_arguments.json \
    -e wf_definition=entrypoint_bfile \
    --rm rtibiocloud/t1dgrs2_pipeline:v3.0_32415e4

# Interactive
docker run -ti \
    -u docker \
    -v /shared/ngaddis:/shared/ngaddis \
    --entrypoint /bin/bash \
    -e wf_arguments=/shared/ngaddis/data/temp/t1d/entrypoint_bfile_arguments.json \
    -e wf_definition=entrypoint_bfile \
    --rm rtibiocloud/t1dgrs2_pipeline:v3.0_32415e4
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/t1dgrs2_pipeline/v3.0

# Local build
docker build . -t t1dgrs2_pipeline/t1dgrs2_pipeline:v3.0

```
</details>

