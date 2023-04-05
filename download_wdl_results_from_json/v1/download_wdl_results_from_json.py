import argparse
import json
import boto3
from urllib.parse import urlparse

# Define the command-line arguments
parser = argparse.ArgumentParser(description='Download files from an S3 bucket based on a JSON file containing the file URLs')
parser.add_argument('--bucket', '-b', required=True, help='The name of the S3 bucket')
parser.add_argument('--file', '-f', required=True, help='The name of the JSON file containing the file URLs')

# Parse the command-line arguments
args = parser.parse_args()
bucket_name = args.bucket
results_file = args.file

# Create an S3 client
s3 = boto3.client('s3')

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

