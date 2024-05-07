# Manifest Generation (AWS)

This Dockerfile sets up an environment for generating a manifest of objects in a S3 bucket.

## Overview

This was created to automate the generation of manifests (including MD5 checksums and DOIs) within BDC powered by Seven Bridges. The manifests are created before any data can be ingested into BDC, but this dockerfile would be useful in 



## Usage

`entrypoint.sh` will configure AWS CLI and run the manifest generation script (`generate_manifest_for_aws.py`). If a [AWS credential file](https://github.com/aws/aws-cli) is available (e.g., `~/.aws/credentials`), quickest way to get started is to pass those credentials in as environment variables.

```
export AWS_PROFILE="<PROFILE_NAME>" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
```
Replace `<PROFILE_NAME>` with the section name within the INI-formatted credentials file.
The only additional thing needed is the name of the S3 bucket (`export S3_BUCKET="somebucket"`).

Example Docker run command:

```
docker run \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    -e S3_BUCKET="$S3_BUCKET" \
    -it <IMAGE_NAME>
```
Replace `<IMAGE_NAME>` with the image name created from the Dockerfile.

## Build
The following command can be used to build this Docker image, following command:
```
docker build -rm -t generate_manifest:v1.0 .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.

`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.

`-t generate_manifest:1.0`: The -t flag specifies the name and tag for the image. In this case, it's named generate_manifest with version v1.0.

`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. It's the default so not needed.

`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.

Running this command will build a Docker image with the name `generate_manifest:1.0`. Make sure the build occurs in the the directory containing the Dockerfile used for building the image.


## Perform a testrun

```
AWS_PROFILE="nhlbi" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
export S3_BUCKET="somebucket"

docker run \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    -e S3_BUCKET="$S3_BUCKET" \
    -it generate_manifest:1.0
```

From within the interactive session, trigger `entrypoint.sh` to 1.) configure AWS CLI, and 2.) generate the manifest. This can be repeated as many times as desired. 

> bash /opt/entrypoint.sh


<details>

```
[[ configure_aws_cli.sh ]]
>>> Configuring aws cli...
[[ Generate manifest for s3://rti-test-bucket ]]
main app started
Script running on linux with 8 cpus
s3-bucket: rti-test-bucket
md5sum exists for s3://rti-test-bucket/aggregate-all-proj-billing-report.csv
md5sum exists for s3://rti-test-bucket/billing-budget-alert-email.png
md5sum exists for s3://rti-test-bucket/var_report.xml
md5sum exists for s3://rti-test-bucket/test.txt.gz
md5sum exists for s3://rti-test-bucket/test.txt
Elapsed time for md5 checksums (calculate_md5sum_for_cloud_paths_threaded): 0:00:00.003184
get_receipt_manifest_file_pointer_for_bucket - done
update_manifest_file - done
Copied rti-test-bucket.manifest.20240506182516.tsv to /opt/output/rti-test-bucket.manifest.20240506182516.tsv
Uploading rti-test-bucket.manifest.20240506182516.tsv to s3://rti-test-bucket done
Done. Receipt manifest located at rti-test-bucket.manifest.20240506182516.tsv
[[ List manifest files in s3://rti-test-bucket ]]
2024-05-06 18:25:17      20721 rti-test-bucket.manifest.20240506182516.tsv
```
</details>
<br>

## Output

A TSV file will be generated locally and uploaded to the S3 bucket. The manifest will look something like the following:

| input_file_path                                            | file_name                                                  | s3_file_size | s3_md5sum                           | md5sum                           | s3_path                                                    | s3_modified_date          | guid                                         | ga4gh_drs_uri                                                |
| ---------------------------------------------------------- | ---------------------------------------------------------- | ------------ | ----------------------------------- | -------------------------------- | ---------------------------------------------------------- | ------------------------- | -------------------------------------------- | ------------------------------------------------------------ |
| s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | 509754247    | dbf2a67bfc6b609363f99bcf8d0c3799-30 | b1f79144c782e699e004e78f2da099e7 | s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | 2020-01-01 21:05:40+00:00 | dg.1212/0e0877ba-731b-4ce9-b266-34b71e6d6322 | drs://dg.1212:dg.1212%2F0e0877ba-731b-4ce9-b266-34b71e6d6322 |
| s3://rti-test-bucket/billing-budget-alert-email.png        | s3://rti-test-bucket/billing-budget-alert-email.png        | 1345755      | 2992b062c8ce8876cdcc552e233c6c3c    | 2992b062c8ce8876cdcc552e233c6c3c | s3://rti-test-bucket/billing-budget-alert-email.png        | 2020-01-01 21:05:52+00:00 | dg.1212/dfafc275-1206-4684-8368-512b4ae479ec | drs://dg.1212:dg.1212%2Fdfafc275-1206-4684-8368-512b4ae479ec |
| s3://rti-test-bucket/var_report.xml                        | s3://rti-test-bucket/var_report.xml                        | 1380403      | 7845dda8786244538b5ebb826021af1d    | 7845dda8786244538b5ebb826021af1d | s3://rti-test-bucket/var_report.xml                        | 2020-01-01 21:05:56+00:00 | dg.1212/14cccdae-c671-4abe-b1fd-b288b15eff38 | drs://dg.1212:dg.1212%2F14cccdae-c671-4abe-b1fd-b288b15eff38 |
| s3://rti-test-bucket/test.txt.gz                           | s3://rti-test-bucket/test.txt.gz                           | 924487       | e18ece94da761771c8bbdb9b8be3d0db    | e18ece94da761771c8bbdb9b8be3d0db | s3://rti-test-bucket/test.txt.gz                           | 2020-01-01 21:06:00+00:00 | dg.1212/e2ac1985-db23-4bfe-bfe1-07a476177c66 | drs://dg.1212:dg.1212%2Fe2ac1985-db23-4bfe-bfe1-07a476177c66 |
| s3://rti-test-bucket/test.txt                              | s3://rti-test-bucket/test.txt                              | 79580051     | bc98ca9dfb02a387703603a447644e94-5  | 6ae3f98be14578ea5b3c6c712a442408 | s3://rti-test-bucket/test.txt                              | 2020-01-01 21:05:40+00:00 | dg.1212/5ee01ada-1f63-40ef-a6b2-dc3ce2aa0a03 | drs://dg.1212:dg.1212%2F5ee01ada-1f63-40ef-a6b2-dc3ce2aa0a03 |


## Contact
For additional information or assistance, please contact Ravi Mathur (rmathur@rti.org) or Stephen Hwang(shwang@rti.org).