#!/bin/bash

# Configure AWS CLI
echo "[[ configure_aws_cli.sh ]]"
bash /opt/configure_aws_cli.sh

echo "[[ Generate manifest for s3://$S3_BUCKET ]]"
python3.9 /opt/generate_manifest_for_aws.py --bucket "$S3_BUCKET" --prefix "$PREFIX"

# List and format manifest file paths
echo "[[ List manifest files in s3://$S3_BUCKET ]]"
MANIFEST_FILES=$(aws s3 ls "s3://$S3_BUCKET" | grep ".*manifest.*tsv" | awk -v bucket="$S3_BUCKET" '{print "s3://" bucket "/" $NF}')

# Format all manifest files with a tab and hyphen
FORMATTED_MANIFEST_FILES=$(echo "$MANIFEST_FILES" | awk '{print "\\t- " $0}')

# Escape newline characters for JSON compatibility
ESCAPED_MANIFEST_BODY=$(echo "$FORMATTED_MANIFEST_FILES" | sed ':a;N;$!ba;s/\n/\\n/g')

# Find the most recently generated manifest file
MOST_RECENT_FILE=$(aws s3 ls "s3://$S3_BUCKET" | grep ".*manifest.*" | sort -k1,1 -k2,2 | tail -n 1 | awk -v bucket="$S3_BUCKET" '{print "s3://" bucket "/" $NF}')

# Define the API endpoint
URL="https://nhlbijira.nhlbi.nih.gov/rest/api/2/issue/{$JIRA_ISSUE_ID}"

# Define the JSON payload
PAYLOAD=$(cat <<EOF
{
  "update": {
    "assignee": [
      {
        "set": {
          "name": "shwang"
        }
      }
    ],
    "description": [
      {
        "set": "This is a test for the DMC Task 4, which will not be used for BDC ingestion. This is a test issue for development purposes."
      }
    ],
    "comment": [
      {
        "add": {
          "body": "AWS manifest generated:\\n\\t- $MOST_RECENT_FILE\\n\\nAll manifests in $S3_BUCKET:\\n$ESCAPED_MANIFEST_BODY"
        }
      }
    ]
  }
}
EOF
)

# Define headers
HEADERS=(
  "-H" "Accept: application/json"
  "-H" "Content-Type: application/json"
  "-H" "X-Atlassian-Token: no-check"
  "-H" "X-Force-Accept-Language: true"
  "-H" "Authorization: Bearer $JIRA_AUTH_TOKEN"
)

# Make the API request
echo "Making API request to update Jira issue..."
curl -X PUT "${HEADERS[@]}" -d "$PAYLOAD" "$URL"
