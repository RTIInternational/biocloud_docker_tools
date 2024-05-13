#!/bin/bash

# Activate the Google Cloud service account with the credentials file
# Check if file or json environment variables exist
if [ -n "$GC_ADC_FILE" ]; then
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="$GC_ADC_FILE"
# If container binding is not supported, create temporary adc.json file
elif [ -n "$GC_ADC_JSON" ]; then
    echo "--- GC_ADC_JSON detected ---"
    echo "[[ Create Google Service Account key file ]]"
    echo $GC_ADC_JSON > /opt/adc.json
    echo "[[ Activating Google Cloud service account ]]"
    gcloud auth activate-service-account --key-file="/opt/adc.json"
else
    echo "GC_ADC_FILE or GC_ADC_JSON not detected."
    exit 1
fi
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

# If temp adc.json was created, clean it up
if [ -n "$GC_ADC_JSON" ]; then
    echo "[[ Cleanup GAC key file ]]"
    rm /opt/adc.json
fi