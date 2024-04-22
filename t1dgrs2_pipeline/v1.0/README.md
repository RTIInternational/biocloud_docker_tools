<details>
<summary>Usage</summary>

``` shell
# gvcf input
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/ancestry_pipeline_args.json \
    --rm ancestry_pipeline/ancestry_pipeline:v1.0

# other entrypoint
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    --entrypoint /opt/entrypoint_plink_input.sh \
    -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/b38/ancestry_pipeline_args.json \
    --rm ancestry_pipeline/ancestry_pipeline:v1.0

# Interactive
docker run -ti \
    -v /rti-01/ngaddis:/rti-01/ngaddis \
    --entrypoint /bin/bash \
    -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/ancestry_pipeline_args.json \
    --rm ancestry_pipeline/ancestry_pipeline:v1.0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/t1dgrs2_pipeline/v1.0

# Local build
docker build . -t t1dgrs2_pipeline/t1dgrs2_pipeline:v1.0

```
</details>


<details>
<summary>Update t1dgrs2 submodule</summary>

``` shell
git submodule update --remote t1dgrs2
git add t1dgrs2
git commit -m "Pulled latest commit from biocloud_wdl_tools"
git push origin master

```
</details>
