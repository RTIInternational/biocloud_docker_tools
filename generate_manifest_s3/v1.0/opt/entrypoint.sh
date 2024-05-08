#!/bin/bash

# Configure AWS CLI
echo "[[ configure_aws_cli.sh ]]"
bash /usr/local/bin/configure_aws_cli.sh

echo "[[ Generate manifest for s3://$S3_BUCKET ]]"
python3.9 /opt/generate_manifest_for_aws.py --bucket "$S3_BUCKET"

# List the contents of the specified Google Cloud Storage bucket
echo "[[ List manifest files in s3://$S3_BUCKET ]]"
aws s3 ls "s3://$S3_BUCKET" | grep ".*manifest.*"

# # Empirical pause before exiting

# # while :; do
# #   sleep 300
# # done

# # exec "$@"
# sleep 30
# # trap ctrl-c and call ctrl_c()
# trap ctrl_c INT

# function ctrl_c() {
#         echo "** Tropted CTRL-C"
# }

# for i in $(seq 1 5); do
#     sleep 1
#     echo -n "."
# done