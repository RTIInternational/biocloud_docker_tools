<details>
<summary>Usage</summary>

``` shell
docker run -ti -v /rti-01/ngaddis:/rti-01/ngaddis -e wf_arguments=/rti-01/ngaddis/data/temp/ancestry/test1/ancestry_pipeline_arguments.json --rm ancestry_pipeline/ancestry_pipeline:v1.0 --entrypoint /bin/bash --
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
cd biocloud_docker_tools/ancestry_pipeline/v1.0

# Local build
docker build . -t ancestry_pipeline/ancestry_pipeline:v1.0

```
</details>
