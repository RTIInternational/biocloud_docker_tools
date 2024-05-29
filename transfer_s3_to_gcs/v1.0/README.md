# Transfer S3 to Google Storage

## Overview
This Dockerfile sets up an environment to create a transfer job (using Google's Cloud Storage Transfer Service) via a Google service account which ultimately results in creating a Google Storage (GS) bucket that mirrors a AWS S3 bucket.

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
export ADC_JSON="{    \"type\": \"service_account\",    \"project_id\": \"rti-gcp-test-project\",    \"private_key_id\": \"abcdefghijlkmnopqrstuvwxyz\",    \"private_key\": \"-----BEGIN PRIVATE KEY-----\n987654321abcdefgh\n-----END PRIVATE KEY-----\n\",    \"client_email\": \"rti-srvc-accnt@rti-gcp-test-project.iam.gserviceaccount.com\",    \"client_id\": \"113491005989622502054\",    \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",    \"token_uri\": \"https://oauth2.googleapis.com/token\",    \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",    \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/rti-srvc-accnt%40rti-gcp-test-project.iam.gserviceaccount.com\",    \"universe_domain\": \"googleapis.com\"  }"
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
docker build -rm -t transfer_s3_to_gcs:v1.0 .`
```
Here's what each part of the command does:

`docker build`: This command tells Docker to build an image.

`--rm`: This flag removes any intermediate containers that are created during the build process, helping to keep your system clean.

`-t transfer_s3_to_gcs:v1.0`: The -t flag specifies the name and tag for the image. In this case, it's named transfer_s3_to_gcs with version v1.0.

`-f Dockerfile`: This flag specifies the Dockerfile to use for building the image. It's the default so not needed.

`.`: The dot at the end of the command indicates that the build context is the current directory, where the Dockerfile is located.

Running this command will build a Docker image with the name `transfer_s3_to_gcs:v1.0`. Make sure the build occurs in the the directory containing the Dockerfile used for building the image.


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
  --rm -it transfer_s3_to_gcs:v1.0
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
  -it transfer_s3_to_gcs:v1.0
```

From within the interactive session, trigger `/opt/entrypoint.sh` to 1.) activate the Google Service Account, and 2.) create a Google transfer job.
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
[[ aws s3 - copy most recently generated manifest .tsv from s3://rti-test-bucket]]
download: s3://rti-test-bucket/rti-test.manifest.20240508150623.tsv to ./rti-test.manifest.20240508150623.tsv
Pulled {rti-test.manifest.20240508150623.tsv}
--- GC_ADC_JSON detected ---
[[ Create Google Service Account key file ]]
[[ Activating Google Cloud service account ]]
Activated service account credentials for: [rti-srvc-accnt@rti-gcp-test-project.iam.gserviceaccount.com]
[[ Create temporary AWScreds.txt file ]]
[[ Initiate transfer from s3:// to gs://rti-test-bucket ]]
creationTime: '2024-05-08T16:33:30.446605065Z'
description: rti-test-bucket
lastModificationTime: '2024-05-08T16:33:30.446605065Z'
loggingConfig: {}
name: transferJobs/rti-test-bucket
projectId: rti-gcp-test-project
schedule:
  scheduleEndDate:
    day: 8
    month: 5
    year: 2024
  scheduleStartDate:
    day: 8
    month: 5
    year: 2024
status: ENABLED
transferSpec:
  awsS3DataSource:
    bucketName: rti-test-bucket
  gcsDataSink:
    bucketName: rti-test-bucket
[[ Cleanup AWScreds.txt file ]]
[[ List manifest files in gs://rti-test-bucket ]]
[[ List all objects in gs://rti-test-bucket ]]
[[ Cleanup Google Service Account key file ]]
```
</details>
<br>

## Reference
Some helpful resources in troubleshooting common problems with the Google service account.

- https://cloud.google.com/iam/docs/best-practices-service-accounts
- https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys
- https://serverfault.com/questions/848580/how-to-use-google-application-credentials-with-gcloud-on-a-server
- https://stackoverflow.com/questions/43278622/gcloud-auth-activate-service-account-error-please-ensure-provided-key-file-is
- https://stackoverflow.com/questions/68290090/set-up-google-cloud-platform-gcp-authentication-for-terraform-cloud/74362252#74362252

## Contact
For additional information or assistance, please contact Ravi Mathur (rmathur@rti.org) or Stephen Hwang(shwang@rti.org).