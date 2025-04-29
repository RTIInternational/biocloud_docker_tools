import argparse
import boto3
from datetime import datetime
import json
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_access_key_id',
    help='AWS access key ID for profile used to run workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--aws_secret_access_key',
    help='AWS secret access key ID for profile used to run workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--aws_region_name',
    help='AWS region in which to run workflow',
    type = str,
    required = True
)
args = parser.parse_args()

# Open AWS Healthomics session
session = boto3.Session(aws_access_key_id=args.aws_access_key_id, aws_secret_access_key=args.aws_secret_access_key, region_name=args.aws_region_name)
omics = session.client('omics')

# Cancel all running jobs
for job in omics.list_runs(status='RUNNING')['items']:
    response = omics.cancel_run(id = job['id'])
