# Download WDL Results from JSON

This script downloads files specified in a JSON file from an S3 bucket using the AWS SDK for Python (Boto3). This script is commonly used to download results from a JSON that contains the results created from the automated WDL workflow.


<br><br>

## Prerequisites

To use this script, you will need to have the following:
- Docker installed on your computer
- An AWS account with access keys and a properly configured AWS CLI



<br>


## Usage
Download results JSON from S3:
```bash
$ curl -X GET "http://localhost:8000/api/workflows/v1/$job/outputs" > outputs.json
```

Run the Docker container. Make sure the `outputs.json` file is in your PWD:
```bash
$ docker run -it -v $PWD/:/data rtibiocloud/download_wdl_results_from_json:<latest-tag> \
    --bucket <s3-bucket-name> \
    --file <outputs-json-file> \
    --aws-access-key-id <access-key-id> \
    --aws-secret-access-key <secred-access-key>
```

- view DockerHub for the latest tag: https://hub.docker.com/repository/docker/rtibiocloud/download_wdl_results_from_json/tags?page=1&ordering=last_updated

example: 
```
$ docker run -it -v $PWD/:/data rtibiocloud/download_wdl_results_from_json:v1_5cc8134 \
    --bucket rti-cromwell-output \
    --file /data/outputs.json \
    --aws-access-key-id AKIA12345 \
    --aws-secret-access-key abcde12345
```

<br>

Alternatively, you could run the Docker container interactively. Make sure the `outputs.json` file is in your PWD:
```bash
$ docker run -it -v $PWD/:/data --entrypoint /bin/bash rtibiocloud/download_wdl_results_from_json 
```


<br><br>
  
## Contact

If you have any questions or suggestions, please feel free to contact Jesse Marks at jmarks@rti.org.
