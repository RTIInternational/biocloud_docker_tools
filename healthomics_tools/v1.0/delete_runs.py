import argparse
import boto3
import re

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_access_key_id',
    help = 'AWS access key ID for profile used to run workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--aws_secret_access_key',
    help = 'AWS secret access key ID for profile used to run workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--aws_region_name',
    help = 'AWS region in which to run workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--run_status',
    help = 'Status of runs to delete',
    type = str,
    choices = ['PENDING','STARTING','RUNNING','STOPPING','COMPLETED','DELETED','CANCELLED','FAILED'],
    required = False
)
parser.add_argument(
    '--delete_run_data',
    help = 'Flag indicating whether to delete data associated with run',
    action = 'store_true'
)
parser.add_argument(
    '--run_output_dir',
    help='Output directory of runs to delete; required if --delete_run_data flag set',
    type = str,
    required = False
)

args = parser.parse_args()
run_output_dir = args.run_output_dir if (args.run_output_dir[-1] == "/") else (args.run_output_dir + "/")

# Open AWS Healthomics session
session = boto3.Session(aws_access_key_id=args.aws_access_key_id, aws_secret_access_key=args.aws_secret_access_key, region_name=args.aws_region_name)
omics = session.client('omics')
s3 = session.client('s3')

for job in omics.list_runs(status=args.run_status)['items']:
    # Delete output
    if args.delete_run_data:
        bucket = re.search(r"s3://(\S+?)/", run_output_dir + job['id']).groups()[0]
        prefix = re.search(r"s3://\S+?/(.+)", run_output_dir + job['id']).groups()[0]
        s3_objects = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
        for s3_object in s3_objects['Contents']:
            s3.delete_object(Bucket=bucket, Key=s3_object['Key'])
    # Delete run
    response = omics.delete_run(id = job['id'])
