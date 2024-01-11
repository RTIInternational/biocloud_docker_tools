<details>
<summary>Usage</summary>

``` shell
docker run -ti -v /rti-01/ngaddis:/rti-01/ngaddis -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/ancestry_pipeline_args.json --rm biocloud_docker_tools/ancestry_pipeline:v1.0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/ancestry_pipeline/v1.0

# Create Dockerfile from template
perl make_dockerfile.pl

# Local build
docker build . -t biocloud_docker_tools/ancestry_pipeline:v1.0

```
</details>
