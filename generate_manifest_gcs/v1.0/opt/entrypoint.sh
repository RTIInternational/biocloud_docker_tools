#!/bin/bash

# # Configure AWS CLI
echo "[[ configure_aws_cli.sh ]]"
bash /opt/configure_aws_cli.sh

# Get latest manifest file from S3
echo "[[ aws s3 - get most recently generated manifest .tsv from s3://$S3_BUCKET]]"
TSV_FILENAME=$(aws s3 ls s3://$S3_BUCKET | grep ".*manifest.*tsv" | sort | tail -n 1 | awk '{print $4}')
aws s3 cp "s3://$S3_BUCKET/$TSV_FILENAME" "/opt/$TSV_FILENAME"
echo "Pulled {$TSV_FILENAME}"

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

echo "[[ Cleanup gs://$S3_BUCKET of manifest files ]]"
gsutil rm -a "gs://$S3_BUCKET/*manifest*"

echo "[[ Generate manifest for gs://$S3_BUCKET ]]"
python3.9 /opt/generate_manifest_for_gcloud.py \
     --bucket "$S3_BUCKET" \
     --tsv "/opt/$TSV_FILENAME" \
     --threads 1

# List the contents of the specified Google Cloud Storage bucket
echo "[[ List manifest files in gs://$S3_BUCKET ]]"
gsutil ls -r "gs://$S3_BUCKET/*manifest*" 2> /dev/null || true

echo "[[ List all objects in gs://$S3_BUCKET ]]"
gsutil ls -r "gs://$S3_BUCKET"  2> /dev/null || true

if [ -n "$GC_ADC_JSON" ]; then
    echo "[[ Cleanup Google Service Account key file ]]"
    rm /opt/adc.json
fi