#!/bin/bash

# # Configure AWS CLI
# echo "[[ configure_aws_cli.sh ]]"
# bash /opt/configure_aws_cli.sh

# # Get latest manifest file from S3
# echo "[[ aws s3 - copy most recently generated manifest .tsv from s3://$S3_BUCKET]]"
# TSV_FILENAME=$(aws s3 ls s3://$S3_BUCKET | grep ".*manifest.*tsv" | sort | tail -n 1 | awk '{print $4}')
# aws s3 cp "s3://$S3_BUCKET/$TSV_FILENAME" "/opt/$TSV_FILENAME"
# echo "Pulled {$TSV_FILENAME}"

# Activate the Google Cloud service account with the credentials file
# Check if NHLBI_FILE or NHLBI_JSON environment variables exist
if [ -n "$GC_ADC_FILE" ]; then
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="$GC_ADC_FILE"
    # Add the code to handle the case when the variables are set
elif [ -n "$GC_ADC_JSON" ]; then
    echo "--- GC_ADC_JSON detected ---"
    echo "[[ Create Google Service Account key file ]]"
    echo $GC_ADC_JSON > /opt/adc.json
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="/opt/adc.json"

    # Add the code to handle the case when the variables are not set
else
    echo "GC_ADC_FILE or GC_ADC_JSON not detected."
    exit 1
fi


# # If container binding it not supported, create temporary adc.json file
# echo "[[ Create Google Service Account key file ]]"
# echo $GC_ADC_JSON > /opt/adc.json
# echo "[[ Activating Google Cloud service account ]]"
# gcloud auth activate-service-account --key-file="/opt/adc.json"

# otherwise, set GOOGLE_APPLICATION_CREDENTIALS to the path of the service account key file
# https://stackoverflow.com/questions/68290090/set-up-google-cloud-platform-gcp-authentication-for-terraform-cloud/74362252#74362252
# export GOOGLE_APPLICATION_CREDENTIALS=${GC_ADC_FILE}
# gcloud auth activate-service-account --key-file="$GC_ADC_FILE"

echo "[[ Create temporary AWScreds.txt file ]]"
echo "{ \"accessKeyId\": \"$AWS_ACCESS_KEY_ID\", \"secretAccessKey\": \"$AWS_SECRET_ACCESS_KEY\" }" > /opt/AWScreds.txt

echo "[[ Initiate transfer from s3:// to gs://$S3_BUCKET ]]"
gcloud transfer jobs create s3://"$S3_BUCKET" gs://"$S3_BUCKET" \
    --name "$S3_BUCKET" \
    --description "$S3_BUCKET" \
    --source-creds-file /opt/AWScreds.txt \
    --project "$GC_PROJECT" \
    --no-enable-posix-transfer-logs

echo "[[ Cleanup AWScreds.txt file ]]"
rm /opt/AWScreds.txt
# cat /opt/AWScreds.txt

# echo "[[ Cleanup gs://$S3_BUCKET of manifest files ]]"
# gsutil rm -a "gs://$S3_BUCKET/*manifest*"

# # nih-nhlbi-rti-test-gcp-bucket.manifest.20240327030438
# echo "[[ Generate manifest for gs://$S3_BUCKET ]]"
# python3.9 /opt/generate_manifest_for_gcloud.py \
#      --bucket $S3_BUCKET \
#      --tsv "/opt/$TSV_FILENAME" \
#      --threads 1

# List the contents of the specified Google Cloud Storage bucket
echo "[[ List manifest files in gs://$S3_BUCKET ]]"
gsutil ls -r "gs://$S3_BUCKET/*manifest*"

echo "[[ List all objects in gs://$S3_BUCKET ]]"
gsutil ls -r "gs://$S3_BUCKET"

if [ -n "$GC_ADC_JSON" ]; then
    echo "[[ Cleanup Google Service Account key file ]]"
    rm /opt/adc.json
fi