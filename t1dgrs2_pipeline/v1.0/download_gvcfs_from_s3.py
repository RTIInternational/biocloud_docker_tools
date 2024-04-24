import argparse
import boto3
import os
import json

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--source_s3_bucket',
    help='S3 bucket containing files to transfer',
    type = str
)
parser.add_argument(
    '--s3_access_key',
    help='Access key for S3 bucket',
    type = str
)
parser.add_argument(
    '--s3_secret_access_key',
    help='Secret access key for S3 bucket',
    type = str
)
parser.add_argument(
    '--target_dir',
    help='Directory to copy files to',
    type = str
)
parser.add_argument(
    '--downloaded_files',
    help='File containing list of previously downloaded files in the source bucket to ignore',
    type = str
)
parser.add_argument(
    '--download_limit',
    help='Max number of files to download',
    type = int,
    default = 1000
)
args = parser.parse_args()

target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")
os.system("mkdir -p {}".format(target_dir))

#Connecting to S3
session = boto3.Session(aws_access_key_id=args.s3_access_key, aws_secret_access_key=args.s3_secret_access_key)
s3 = session.resource('s3')
my_bucket = s3.Bucket(args.source_s3_bucket)

#Load previously downloaded files
try:
    with open(args.downloaded_files, 'r') as f:
        previous_downloads = json.load(f)
except FileNotFoundError:
    previous_downloads = {}

#Make list of files that have NOT been downloaded yet
s3_objects = [file for file in my_bucket.objects.all() if file.key not in previous_downloads]

#Loop over list of new files to be downloaded
download_limit = args.download_limit
for s3_object in s3_objects:
    directory, filename = os.path.split(s3_object.key)
    path = "{}{}".format(target_dir, filename)
    if (download_limit > 0):
        my_bucket.download_file(s3_object.key, path)
        print(f'Downloaded file {s3_object.key}')

        if (".xlsx" in s3_object.key):
            download_limit = download_limit - 1
        else:
            # Add the file to the list of downloaded files
            previous_downloads[s3_object.key] = "DOWNLOADED"

            # Save the list of downloaded files
            with open(args.downloaded_files, 'w') as f:
                json.dump(previous_downloads, f)
        
            download_limit = download_limit - 1
