#!/bin/bash

set -e 

# If test-bucket, then GCS bucket is 
if [ "$S3_BUCKET" == "nih-nhlbi-rti-test-gcp-bucket" ]; then
    GCS_BUCKET="nih-nhlbi-bdc-manifest-gen-ftre-testing"
else
    GCS_BUCKET="$S3_BUCKET"
fi

echo "[[ S3_BUCKET: $S3_BUCKET ]]"
echo "[[ GCS_BUCKET: $GCS_BUCKET ]]"

# Activate the Google Cloud service account with the credentials file
# Check if file or json environment variables exist
if [ -n "$GC_ADC_FILE" ]; then
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="$GC_ADC_FILE" --no-user-output-enabled
elif [ -n "$GC_ADC_JSON" ]; then
    echo "--- GC_ADC_JSON detected ---"
    echo "[[ Create Google Service Account key file ]]"
    echo $GC_ADC_JSON > /opt/adc.json
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="/opt/adc.json" --no-user-output-enabled
else
    echo "GC_ADC_FILE or GC_ADC_JSON not detected."
    exit 1
fi

echo "[[ Set Google Cloud project ]]"
gcloud config set project $GC_PROJECT

echo "[[ Create temporary AWScreds.txt file ]]"
echo "{ \"accessKeyId\": \"$AWS_ACCESS_KEY_ID\", \"secretAccessKey\": \"$AWS_SECRET_ACCESS_KEY\" }" > /opt/AWScreds.txt

echo "*** Running gcloud command to find transfer jobs"

JOB_NAME=$(gcloud transfer jobs list --job-names="$S3_BUCKET" --format="value(name)")
echo "JOB_NAME: {{{ $JOB_NAME }}}"

if [ -z "$JOB_NAME" ]; then
    echo "Job does not exist."
    echo "[[ Initiate transfer from s3://$S3_BUCKET to gs://$GCS_BUCKET ]]"
    TRANSFER_JOB_ID=$(gcloud transfer jobs create s3://"$S3_BUCKET" gs://"$GCS_BUCKET" \
    --name "$S3_BUCKET" \
    --description "s3://$S3_BUCKET to gs://GCS_BUCKET" \
    --source-creds-file "/opt/AWScreds.txt" \
    --project "$GC_PROJECT" \
    --overwrite-when 'different' \
    --delete-from 'destination-if-unique' \
    --no-enable-posix-transfer-logs \
    --format="value(name)")
    echo "Waiting for the transfer job to be fully registered..."
    sleep 15  # Adjust this time if needed based on your observations
    echo "***TRANSFER_JOB_ID: {{{ $TRANSFER_JOB_ID }}}"

else
    echo "Job exists."
    gcloud transfer jobs update "$S3_BUCKET" \
        --clear-source-creds-file \
        --source="s3://$S3_BUCKET" \
        --destination="gs://$GCS_BUCKET" \
        --delete-from destination-if-unique \
        --overwrite-when different 

    TRANSFER_JOB_ID=$(gcloud transfer jobs describe "$S3_BUCKET" --format="value(latestOperationName)")
    echo "***TRANSFER_JOB_ID: {{{ $TRANSFER_JOB_ID }}}"

    if ! gcloud transfer jobs run "$S3_BUCKET" --project "$GC_PROJECT"; then
        echo "Error: Failed to run transfer job for $S3_BUCKET"
        exit 1
    fi
fi



echo "[[ Cleanup AWScreds.txt file ]]"
rm /opt/AWScreds.txt

# Check the status of the transfer job until it completes or fails
while true; do
    STATUS=$(gcloud transfer operations describe "$TRANSFER_JOB_ID" \
            --format="value(metadata.status)")

    if [ "$STATUS" == "SUCCESS" ]; then
        echo "Transfer job completed successfully."
        exit 0
    elif [ "$STATUS" == "FAILED" ]; then
        echo "Transfer job failed."
        exit 1
    else
        echo "Transfer job status: $STATUS. Checking again in 10 seconds..."
        sleep 10
    fi
done

# If temp adc.json was created, clean it up
if [ -n "$GC_ADC_JSON" ]; then
    echo "[[ Cleanup GAC key file ]]"
    rm /opt/adc.json
fi