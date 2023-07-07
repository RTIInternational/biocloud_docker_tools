import argparse
import json
import boto3
from urllib.parse import urlparse

"""
Downloads files from an S3 bucket based on a JSON file containing the file URLs.

Usage:
  python download_files_from_s3.py [--bucket BUCKET_NAME] --file JSON_FILE_NAME --aws-access-key-id ACCESS_KEY_ID --aws-secret-access-key SECRET_ACCESS_KEY

Arguments:
  --bucket (-b)         The name of the S3 bucket (default: "rti-cromwell-output")
  --file (-f)           The name of the JSON file containing the file URLs (required)
  --aws-access-key (-a) AWS access key ID (required)
  --aws-secret-access-key (-s) AWS secret access key (required)

Example:
  To download files from an S3 bucket named 'my-bucket' based on a JSON file named 'file_list.json' using AWS access key ID 'AKIA12345' and AWS secret access key 'abcde12345':
  $ python download_files_from_s3.py --bucket my-bucket --file file_list.json --aws-access-key-id AKIA12345 --aws-secret-access-key abcde12345
"""



# Define the command-line arguments
parser = argparse.ArgumentParser(description='Download files from an S3 bucket based on a JSON file containing the file URLs')
parser.add_argument('--bucket', '-b', required=False, default="rti-cromwell-output", help='The name of the S3 bucket')
parser.add_argument('--file', '-f', required=True, help='The name of the JSON file containing the file URLs')
parser.add_argument('--aws-access-key', '-a', required=True, type=str, help='AWS access key ID')
parser.add_argument('--aws-secret-access-key', '-s', required=True, type=str, help='AWS secret access key')


# Parse the command-line arguments
args = parser.parse_args()
bucket_name = args.bucket
results_file = args.file

# Create an S3 client
s3 = boto3.client(
        's3',
        aws_access_key_id = args.aws_access_key,
        aws_secret_access_key = args.aws_secret_access_key
        )

def download_parsed(parsed_url):
    filename = parsed_url.path.split('/')[-1]
    key = parsed_url.path[1:]
    print(bucket_name, key, filename)
    s3.download_file(bucket_name, key, filename)

# Load the JSON file
with open(results_file) as f:
    data = json.load(f)

# Download the files
for url in data['outputs'].values():
    if type(url) == list:
        for list_item in url:
            download_parsed(urlparse(list_item))
    else:
        download_parsed(urlparse(url))

