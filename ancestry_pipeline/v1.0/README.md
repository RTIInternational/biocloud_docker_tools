<details>
<summary>Usage</summary>

``` shell
docker run -ti \
    -v /shared/ngaddis:/shared/ngaddis \
    -e wf_arguments=/shared/ngaddis/data/temp/ancestry_weiss/ancestry_pipeline_entrypoint_bfile_superpop_arguments.json \
    -e wf_definition=ancestry_pipeline_entrypoint_bfile \
    --rm ancestry_pipeline/ancestry_pipeline:v1.0

docker run -ti \
    -v /shared/ngaddis:/shared/ngaddis \
    --entrypoint bash \
    --rm ancestry_pipeline/ancestry_pipeline:v1.0

```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/ancestry_pipeline/v1.0

# Create Dockerfile from template
./docker/make_dockerfile.pl

# Local build
docker build . -t ancestry_pipeline/ancestry_pipeline:v1.0

```
</details>
