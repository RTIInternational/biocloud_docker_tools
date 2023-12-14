<details>
<summary>Usage</summary>

``` shell
docker run -ti -v /rti-01/ngaddis:/rti-01/ngaddis -e wf_arguments=/rti-01/ngaddis/data/temp/t1d_test3/ancestry_pipeline_test.json --rm biocloud_docker_tools/ancestry_pipeline:v1.0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
base_dir=/rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0
cd $base_dir

# Create Dockerfile from template
perl make_dockerfile.php

# Local build
docker build . -t biocloud_docker_tools/ancestry_pipeline:v1.0

```
</details>
