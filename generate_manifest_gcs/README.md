# # Manifest Generation (GCP)

## Overview
This Dockerfile sets up an environment to 1.) interact with AWS cloud resources, and 2.) to generate an [inventory manifest](#output) of objects in an Google Storage bucket with relevant metadata, including the md5checksum/etag, file size, modified date, and more. This is done by grabbing the inventory manifest file from the corresponding S3 bucket. Command line tools, like AWS CLI, `gcloud`, `gsutil`, and `bq`, are available from this image.


## Setup

In order to leverage this tool, you must have a [Google service account](https://cloud.google.com/iam/docs/service-account-overview) set up. 
- Specifically, a [user-managed service account](https://cloud.google.com/iam/docs/service-account-types#user-managed) is needed.
    - When you creating a user-managed service account in a Google project, a name for the service account is chosen and it appears in the email address that identifies the service account using the following format: `<SERVICE-ACCOUNT-NAME>@<PROJECT-ID>.iam.gserviceaccount.com`

- AWS roles and Google Cloud service accounts are similar in that they both provide ways to delegate permissions and manage access control within their respective cloud environments. Both are used to grant specific permissions to applications, services, or users, allowing them to perform tasks that require access to resources within the cloud environments.

[Application Default Credentials (ADC)](https://cloud.google.com/iam/docs/service-account-creds) are used for authenticating the service account.
- Step-by-step instructions for creating a ADC file can be found [here](https://cloud.google.com/docs/authentication/provide-credentials-adc). 

For best practices for using service accounts, please see the [documentation](https://cloud.google.com/iam/docs/best-practices-service-accounts).


## Usage

### Setup
`entrypoint.sh` will configure AWS CLI and activate the Google service account. 
If a [AWS credential file](https://github.com/aws/aws-cli) is available (e.g., `~/.aws/credentials`), the quickest way to get started is to pass those credentials in as environment variables.

```
export AWS_PROFILE="<PROFILE_NAME>" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
```
- Replace `<PROFILE_NAME>` with the section name within the INI-formatted credentials file.

Then, set `GC_PROJECT` to the name of the Google Cloud project: `export GC_PROJECT="rti-gcp-test-project"`

Then, set `S3_BUCKET` environment variable to the name of the S3 bucket that will be copied, without the `s3://` prefix: `export S3_BUCKET="rti-test-bucket"`

### Running the image as a container
Finally, set an environment variable `PATH_TO_ADC_JSON` as the local system path of the [Application Default Credential file](#setup) generated for the service account: `export PATH_TO_ADC_JSON="/path/to/adc.json"`

Then run the following Docker run command:
```
docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_FILE="/opt/adc.json" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  --mount type=bind,source="$PATH_TO_ADC_JSON",target="/opt/adc.json" \
  --rm -it <IMAGE_NAME>
```
- Replace `<IMAGE_NAME>` with the `image:tag` created from the Dockerfile.

Alternatively, if the credential file cannot be passed in, set an environment variable `$ADC_JSON` to the contents of the credential file (e.g. json) as a string.

```
export ADC_JSON="{    \"type\": \"service_account\",    \"project_id\": \"rti-gcp-test-project\",    \"private_key_id\": \"abcdefghijlkmnopqrstuvwxyz\",    \"private_key\": \"-----BEGIN PRIVATE KEY-----\n987654321abcdefgh\n-----END PRIVATE KEY-----\n\",    \"client_email\": \"rti-srvc-accnt@rti-gcp-test-project.iam.gserviceaccount.com\",    \"client_id\": \"123456789000987654321\",    \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",    \"token_uri\": \"https://oauth2.googleapis.com/token\",    \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",    \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/rti-srvc-accnt%40rti-gcp-test-project.iam.gserviceaccount.com\",    \"universe_domain\": \"googleapis.com\"  }"
```

and run the following Docker run command:
```
docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_JSON="$ADC_JSON" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  -it <IMAGE_NAME>
```


## Build
The following command can be used to build this Docker image, following command:
```
docker build -rm -t generate_manifest:v1.0 .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.

`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.

`-t generate_manifest:v1.0`: The -t flag specifies the name and tag for the image. In this case, it's named generate_manifest with version v1.0.

`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. It's the default so not needed.

`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.

Running this command will build a Docker image with the name `generate_manifest:v1.0`. Make sure the build occurs in the the directory containing the Dockerfile used for building the image.


## Perform a testrun

```
export AWS_PROFILE="nhlbibdc" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
export S3_BUCKET="rti-test-bucket"
export GC_PROJECT="rti-gcp-test-project"
export PATH_TO_ADC_JSON="/local/path/to/rti-access.json"

docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_FILE="/opt/adc.json" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  --mount type=bind,source="$PATH_TO_ADC_JSON",target="/opt/adc.json" \
  --rm -it generate_manifest:v1.0
```

When the service account credential file cannot be passed in, pass in the credential json as string `$ADC_JSON`.
```
export AWS_PROFILE="nhlbibdc" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
export S3_BUCKET="rti-test-bucket"
export GC_PROJECT="rti-gcp-test-project
export ADC_JSON="{    \"type\": \"service_account\",    \"project_id\": \"rti-gcp-test-project\",    \"private_key_id\": \"abcdefghijlkmnopqrstuvwxyz\",    \"private_key\": \"-----BEGIN PRIVATE KEY-----\n987654321abcdefgh\n-----END PRIVATE KEY-----\n\",    \"client_email\": \"rti-srvc-accnt@rti-gcp-test-project.iam.gserviceaccount.com\",    \"client_id\": \"113491005989622502054\",    \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",    \"token_uri\": \"https://oauth2.googleapis.com/token\",    \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",    \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/rti-srvc-accnt%40rti-gcp-test-project.iam.gserviceaccount.com\",    \"universe_domain\": \"googleapis.com\"  }"


docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_JSON="$ADC_JSON" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  -it generate_manifest:v1.0
```

From within the interactive session, trigger `entrypoint.sh` to activate the Google Service Account and generate the manifest on the Google Strorage bucket.
- Verify credentials were applied by running `gcloud auth list`

Note: A transfer job can be created one time for each Google Storage bucket. If a job needs to be repeated, use the `--run` flag on `/opt/entrypoint.sh`.

In order to do that:
1. set project name for gcloud to the project name ( `gcloud config set project "$GC_PROJECT"` )
2. find the name of the transfer job ( `gcloud transfer operations list` )
3. run the transfer job with `bash /opt/entrypoint.sh --run`

Transfer jobs can be monitored through `gcloud transfer operations list`.
Once the job is complete, Google Storage buckets can be examined with `gsutil ls -r $S3_BUCKET`

If the original configuration of a job needs to be updated, find the name of the transfer job and update it with: `gcloud transfer jobs update JOB_NAME [options]`:

- JOB_NAME is the unique name of the job to update.
- The options that can be updated are listed by running gcloud transfer jobs update --help.

For example, to update the source and destination of a job, and to remove its description, run the following command:

```
gcloud transfer jobs update \
  JOB_NAME \
  --source=gs://new-bucket-1 \
  --destination=gs://new-bucket-2 \
  --clear-description
```


<details>

```
[[ configure_aws_cli.sh ]]
>>> Configuring aws cli...
>>> aws cli configured
[[ Create Google Service Account key file ]]
[[ Activating Google Cloud service account ]]
[[ Create temporary AWScreds.txt file ]]
[[ Cleanup AWScreds.txt file ]]
[[ Cleanup gs://rti-gcp-test-project of manifest files ]]
[[ Generate manifest for gs://rti-gcp-test-project ]]
Script running on linux with 8 cpus
Verifying Uploads and Fetching Metadata
Executing total 15 jobs with 1 threads
Uploading /app/rti-gcp-test-project.manifest.tsv to gs://rti-gcp-test-project
Done. Receipt manifest located at /app/rti-gcp-test-project.manifest.tsv
[[ List manifest files in gs://rti-gcp-test-project ]]
gs://rti-gcp-test-project/rti-gcp-test-project.manifest.tsv
[[ Cleanup Google Service Account key file ]]
```
</details>
<br>

<!-- ## Output -->
<!-- 
A TSV file will be generated locally and uploaded to the S3 bucket. The manifest will look something like the following:

| input_file_path                                            | file_name                                                  | s3_file_size | s3_md5sum                           | md5sum                           | s3_path                                                    | s3_modified_date          | guid                                         | ga4gh_drs_uri                                                |
| ---------------------------------------------------------- | ---------------------------------------------------------- | ------------ | ----------------------------------- | -------------------------------- | ---------------------------------------------------------- | ------------------------- | -------------------------------------------- | ------------------------------------------------------------ |
| s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | 509754247    | dbf2a67bfc6b609363f99bcf8d0c3799-30 | b1f79144c782e699e004e78f2da099e7 | s3://rti-test-bucket/aggregate-all-proj-billing-report.csv | 2020-01-01 21:05:40+00:00 | dg.1212/0e0877ba-731b-4ce9-b266-34b71e6d6322 | drs://dg.1212:dg.1212%2F0e0877ba-731b-4ce9-b266-34b71e6d6322 |
| s3://rti-test-bucket/billing-budget-alert-email.png        | s3://rti-test-bucket/billing-budget-alert-email.png        | 1345755      | 2992b062c8ce8876cdcc552e233c6c3c    | 2992b062c8ce8876cdcc552e233c6c3c | s3://rti-test-bucket/billing-budget-alert-email.png        | 2020-01-01 21:05:52+00:00 | dg.1212/dfafc275-1206-4684-8368-512b4ae479ec | drs://dg.1212:dg.1212%2Fdfafc275-1206-4684-8368-512b4ae479ec |
| s3://rti-test-bucket/var_report.xml                        | s3://rti-test-bucket/var_report.xml                        | 1380403      | 7845dda8786244538b5ebb826021af1d    | 7845dda8786244538b5ebb826021af1d | s3://rti-test-bucket/var_report.xml                        | 2020-01-01 21:05:56+00:00 | dg.1212/14cccdae-c671-4abe-b1fd-b288b15eff38 | drs://dg.1212:dg.1212%2F14cccdae-c671-4abe-b1fd-b288b15eff38 |
| s3://rti-test-bucket/test.txt.gz                           | s3://rti-test-bucket/test.txt.gz                           | 924487       | e18ece94da761771c8bbdb9b8be3d0db    | e18ece94da761771c8bbdb9b8be3d0db | s3://rti-test-bucket/test.txt.gz                           | 2020-01-01 21:06:00+00:00 | dg.1212/e2ac1985-db23-4bfe-bfe1-07a476177c66 | drs://dg.1212:dg.1212%2Fe2ac1985-db23-4bfe-bfe1-07a476177c66 |
| s3://rti-test-bucket/test.txt                              | s3://rti-test-bucket/test.txt                              | 79580051     | bc98ca9dfb02a387703603a447644e94-5  | 6ae3f98be14578ea5b3c6c712a442408 | s3://rti-test-bucket/test.txt                              | 2020-01-01 21:05:40+00:00 | dg.1212/5ee01ada-1f63-40ef-a6b2-dc3ce2aa0a03 | drs://dg.1212:dg.1212%2F5ee01ada-1f63-40ef-a6b2-dc3ce2aa0a03 | 
-->

## Reference
Some helpful resources in troubleshooting common problems with the Google service account.

- https://cloud.google.com/iam/docs/best-practices-service-accounts
- https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys
- https://serverfault.com/questions/848580/how-to-use-google-application-credentials-with-gcloud-on-a-server
- https://stackoverflow.com/questions/43278622/gcloud-auth-activate-service-account-error-please-ensure-provided-key-file-is
- https://stackoverflow.com/questions/68290090/set-up-google-cloud-platform-gcp-authentication-for-terraform-cloud/74362252#74362252

## Contact
For additional information or assistance, please contact Ravi Mathur (rmathur@rti.org) or Stephen Hwang(shwang@rti.org).