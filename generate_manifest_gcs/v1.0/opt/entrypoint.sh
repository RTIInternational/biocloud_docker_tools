#!/bin/bash

# Configure AWS CLI
echo "[[ configure_aws_cli.sh ]]"
bash /opt/configure_aws_cli.sh

# If test-bucket, then GCS bucket is 
if [ "$S3_BUCKET" == "nih-nhlbi-rti-test-gcp-bucket" ]; then
    GCS_BUCKET="nih-nhlbi-bdc-manifest-gen-ftre-testing"
else
    GCS_BUCKET="$S3_BUCKET"
fi

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

echo "[[ Set GAC credentials ]]"
export GOOGLE_APPLICATION_CREDENTIALS="/opt/adc.json"

echo "[[ Set Google Cloud project ]]"
gcloud config set project $GC_PROJECT


echo "[[ Create temporary AWScreds.txt file ]]"
echo "{ \"accessKeyId\": \"$AWS_ACCESS_KEY_ID\", \"secretAccessKey\": \"$AWS_SECRET_ACCESS_KEY\" }" > /opt/AWScreds.txt

echo "[[ Cleanup gs://$GCS_BUCKET of manifest files ]]"
gsutil rm -a "gs://$GCS_BUCKET/*manifest*tsv"

echo "[[ Generate manifest for gs://$GCS_BUCKET ]]"
python3.9 /opt/generate_manifest_for_gcloud.py \
    --bucket "$GCS_BUCKET" \
    --tsv "/opt/$TSV_FILENAME" \
    --threads 1

# List the contents of the specified Google Cloud Storage bucket
echo "[[ List manifest files in gs://$GCS_BUCKET ]]"
gsutil ls -r "gs://$GCS_BUCKET/*manifest*tsv" 2> /dev/null || true

echo "[[ List all objects in gs://$GCS_BUCKET ]]"
gsutil ls -r "gs://$GCS_BUCKET"  2> /dev/null || true

if [ -n "$GC_ADC_JSON" ]; then
    echo "[[ Cleanup Google Service Account key file ]]"
    rm /opt/adc.json
fi
