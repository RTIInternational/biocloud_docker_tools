#!/bin/bash

# Usage: sh run_docker_image.sh <docker_image_name> [<aws_profile_name>]
# Example: sh run_docker_image.sh generate_manifest_nonamd default
# Requirements: credentials stored in ~/.aws/credentials

# First argument = image name
IMAGE_NAME=$1

# Check if image name is provided
if [ -z "$IMAGE_NAME" ]; then
  echo "Error: Image name argument is required"
  echo "Usage: $0 <image_name> [aws_profile]"
  exit 1
fi

# Second argument = bucket name
BUCKET=${2-<BUCKET_NAME>}

# instantiate env variables from terminal
AWS_PROFILE="<PROFILE_NAME>" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)

docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e S3_BUCKET="$S3_BUCKET" \
  -it "<IMAGE_NAME>"

export AWS_PROFILE="nhlbibdc" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
export S3_BUCKET="nih-nhlbi-rti-test-gcp-bucket"

docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="nih-nhlbi-biodatacatalyst-data"
  -it biocloud_gma


# # Interactive mode
# bash /usr/local/bin/configure_aws_cli.sh
# bash /opt/entrypoint.sh
# python3.9 /opt/generate_manifest_for_aws.py --bucket "$S3_BUCKET"

# echo "[[ Remove all objects from gs://$SB_BUCKET ]]"
# gsutil -m rm gs://SB_BUCKET/**
# gsutil rm -a gs://bucket/**

# ********************************************************************************************************************

# nhlbibdc nhlbitopmed
export AWS_PROFILE="nhlbibdc" 
export AWS_ACCESS_KEY_ID=$(aws configure get ${AWS_PROFILE}.aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get ${AWS_PROFILE}.aws_secret_access_key)
export AWS_DEFAULT_REGION=$(aws configure get ${AWS_PROFILE}.default_region)
export S3_BUCKET="nih-nhlbi-rti-test-gcp-bucket"
export GC_PROJECT="nih-nhlbi-biodatacatalyst-data"
export PATH_TO_ADC_JSON="/Users/shwang/Desktop/github/shwang_rtiintl/NHLBI_DMC/manifest_generation/aws_transfer_gcp_slim_string/nhlbi-rti-access/adc.json"
export ADC_JSON="{    \"type\": \"service_account\",    \"project_id\": \"nih-nhlbi-biodatacatalyst-data\",    \"private_key_id\": \"913f54e9f0f0a4d55e9d4cb1d354eafc25cb8b3f\",    \"private_key\": \"-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC4J3mMzGlDEvuO\n+wDO3lO4AYmixxnTGqrlt7wlutcV16Z6aRk5po/Y/wNisBuhC8slV+yXDSrCuGM2\n63m/7dXB0MpCdtQdfQ0fJRlQclIvbJEXf4pi31LpNtPJMpEJnAT+qQStAw5w8tah\ns43ZWsNKuXAb5+qEO1ogOE2jhT6O9aSjj27M1mG7R5kcNXCFtB+f+tevxVPJOmYU\nWVqhPa4uqVSSxDp1nxbHwa6sk0PMlklqoqyderPDZT9SG7iKQ2xzMYWtWlRvAKSZ\nFQ7PEVY7BL0+Vr5r/KK5ZUrY+c4PdDFlkBClHUVz78BufwFinQOPy+kERFSXD9wS\n9Xvz8Lr5AgMBAAECggEADotPlkcuqRV+uLQqRCxbAFVewXRoHbwlcy8ntPMkuZzm\nkRRr4Zm+Eq1RXyH5jKaZzME89lEb53UYoOXIH9hw4XXUA5vO9OVDfAo6DZh51TUF\n4I06KMTqj3C9GU7dFZ0058gBjoiHQ3Rqbyr3MQtyERzENfADHZ5yZ8kKmLeVUUUC\n+/tvfvQrs0sQJsEffn0k1Kc0UwhpJHhovJHSZTMZZRgYfQErxcybX9O6Rb4l7Jer\nLiwXbspO5y4Pq6D2wsu9EL4ffEvm0JonYihzuSxIzBu4mTE8ZD5Jk3a0eWMIeAkl\nYr+YIhNc6Jyc9WCwuqs9XRtc412KhIYrpdmDpQj1YQKBgQDkq/H5tC35pvup1Eve\nFCKUw//kfH+D2MdzvRf415wZlpGtaGwop/DRkNFvjpqtyfSut02bRKiNDh1VRkm8\nH1ihMz3+rAGKKsh6MLfGBqu1pW/IOhnB4d/DGHM8WyOwYFsHagMiFkOKXRA5ucrm\n53th2H5JX9f1haoNyO/5jAXQJwKBgQDOKYxFf1nuomd2HYMt9kj4XyTXycon7soh\n+JAsBkr/aoQv0NcKu3YG3+9Z8ze2UeKBe/lj5mKviYLtIMJvxJx1KtKs3sF9SIYd\nIyE/NM+R7M1OMgulncOPOHlhLrnucnsFyKh8hZO/PsLDJTDVd8UK8p49+V9rO04O\nlbw8cZTv3wKBgQCqVCl5hex4+Rib97ZLRVQ824HP/6w72U03uLISeQedR7pbIFzw\nK6gFcYmPPvmYWcYYHhGAhjPGXa0bx69EoVSzPif/er/q2tNZsNAygOWF+CS7UAu/\njy/NcnjjjD+ZMSyc6SpMSakldwyO8wVf2SzeRRRMM0f5agaxHesiRlpOIQKBgQCe\nJutPiRGRag6aYqt2P9/cgQh/bXJiTeHMS6U10KIJ7El5cOj2d7ZkMbeotlb/yzNK\nh7NaOqtr476HcEEYgqhPjclOChg+prsTcRaZKUcut40LtoKOy0bxAK7EqZbC4BmV\n50exNruP03KPR2F98MI80sAn5LyZQ0ZvE9jyOWO62wKBgFQdzK/IOuO46HXsXmAR\ntuWiZSEadZ0MPFuPxtJaT/EBl9HnIufBa9DAXpoT+G5JHUYFjNfqPF78Me3O3EP6\nWILjQGa1qJdrsY+FYy55Y5ahZvD9AZIZkajoxaakene2iM4kfFMNmcbDDEAkYdxJ\nFBfXLZ1wqKZjj/6vCGk67pLF\n-----END PRIVATE KEY-----\n\",    \"client_email\": \"nhlbi-rti-srvc-accnt@nih-nhlbi-biodatacatalyst-data.iam.gserviceaccount.com\",    \"client_id\": \"113491005989622502054\",    \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",    \"token_uri\": \"https://oauth2.googleapis.com/token\",    \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",    \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/nhlbi-rti-srvc-accnt%40nih-nhlbi-biodatacatalyst-data.iam.gserviceaccount.com\",    \"universe_domain\": \"googleapis.com\"  }"
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_DEFAULT_REGION

nih-nhlbi-rti-test-gcp-bucket
nih-nhlbi-bdc-imaging-fhs-phs003593-c1
nih-nhlbi-bdc-imaging-fhs-phs003593-c2


docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_FILE="/opt/adc.json" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  --mount type=bind,source="$PATH_TO_ADC_JSON",target="/opt/adc.json" \
  --rm -it transfer_s3_to_gcs

gsutil ls -r "gs://nih-nhlbi-bdc-imaging-fhs-phs003593-c1"
gsutil ls -r "gs://nih-nhlbi-bdc-imaging-fhs-phs003593-c2"

docker build -t transfer_s3_to_gcs .
bash /opt/entrypoint.sh


docker run \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
  -e GC_ADC_JSON="$ADC_JSON" \
  -e S3_BUCKET="$S3_BUCKET" \
  -e GC_PROJECT="$GC_PROJECT" \
  -it transfer_s3_to_gcs



export SB_BUCKET="nih-nhlbi-bdc-imaging-fhs-phs003593-c2"
gsutil ls -r "gs://nih-nhlbi-bdc-imaging-fhs-phs003593-c1"
gsutil ls -r "gs://nih-nhlbi-bdc-imaging-fhs-phs003593-c2"

docker build -t transfer_s3_to_gcs .
docker build -t transfer_s3_to_gcs .
docker create transfer_s3_to_gcs
docker commit b2a94dd36b917607928bee57d958b550fc81f88e3a4e0f9f2e3cc544540aa685 images.sb.biodatacatalyst.nhlbi.nih.gov/gnawhnehpets/manifest_generation:transfer_s3_to_gcs_v5
docker push images.sb.biodatacatalyst.nhlbi.nih.gov/gnawhnehpets/manifest_generation:transfer_s3_to_gcs_v5


bash /usr/local/bin/entrypoint.sh

gsutil ls -r "nih-nhlbi-bdc-hfn-rose-phs003589-c1"

gsutil rm -a "gs://$SB_BUCKET/*manifest*"

gsutil ls -r "gs://$SB_BUCKET/*manifest*"

gcloud transfer jobs create s3://"$SB_BUCKET" gs://"$SB_BUCKET" \
    --name "$SB_BUCKET" \
    --description "$SB_BUCKET" \
    --source-creds-file /app/AWScreds.txt \
    --project nih-nhlbi-biodatacatalyst-data

python3.9 /app/generate_manifest_for_gcloud.py \
     --bucket $SB_BUCKET \
     --tsv "/app/nih-nhlbi-bdc-hfn-ironoutDUD-phs003557-c1.manifest.20240411141721.tsv"


# docker run -it generate_manifest_aws_slim
docker build -t aws_transfer_gcp .
docker create aws_transfer_gcp
docker commit 03545c79291348dca1a9f0b3639837497f9527d4dbc2e3af48cfd094a536028a images.sb.biodatacatalyst.nhlbi.nih.gov/gnawhnehpets/manifest_generation:aws_transfer_gcp_v2
docker push images.sb.biodatacatalyst.nhlbi.nih.gov/gnawhnehpets/manifest_generation:aws_transfer_gcp_v2

nih-nhlbi-bdc-hfn-fight-phs003542-c1
nih-nhlbi-topmed-freeze9-batch5-phs001644-c1


gcloud config set project nih-nhlbi-biodatacatalyst-data
gcloud transfer operations list --limit 10

gcloud transfer jobs run nih-nhlbi-topmed-phs000280-v8-c1
gcloud transfer jobs list --job-names nih-nhlbi-topmed-phs000280-v8-c1
