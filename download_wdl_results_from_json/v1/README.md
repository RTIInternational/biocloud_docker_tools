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
```
$ curl -X GET "http://localhost:8000/api/workflows/v1/$job/outputs" > outputs.json
```

Run the Docker container interactively. Make sure the `outputs.json` file is in your PWD:
```
$ docker run -it -v $PWD/:/data rtibiocloud/download_wdl_results_from_json bash
```

Configure AWS so that the awscli has the properly credentials:
```
$ aws configure
```

Download results files listed in the `outputs.json`:
```
python3 /opt/download_wdl_results_from_json.py \
    --bucket <bucket-name> \
    --file outputs.json
```
- if this is from a WDL workflow, then replace <bucket-name> with `rti-cromwell-output`.
  

<br><br>
  
## Contact

If you have any questions or suggestions, please feel free to contact Jesse Marks at jmarks@rti.org.
