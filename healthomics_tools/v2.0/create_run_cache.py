import argparse
import boto3
from datetime import datetime

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_profile',
    help='AWS profile to use for credentials',
    type = str,
    required = True
)
parser.add_argument(
    '--charge_code',
    help='Charge code to assign to run cache',
    type = str,
    required = True
)
parser.add_argument(
    '--cache_s3_location',
    help='S3 location for storing cached task outputs',
    type = str,
    required = True
)
parser.add_argument(
    '--name',
    help='A name for the run cache',
    type = str,
    required = False,
    default = ''
)
parser.add_argument(
    '--description',
    help='Description of the run cache',
    type = str,
    required = False,
    default = ''
)
parser.add_argument(
    '--cache_behavior',
    help='Default cache behavior for runs that use this cache',
    type = str,
    required = False,
    choices = ['', 'CACHE_ON_FAILURE', 'CACHE_ALWAYS'],
    default = ''
)
parser.add_argument(
    '--cache_bucket_owner_id',
    help='AWS account ID of the expected owner of the S3 bucket for the run cache',
    type = str,
    required = False,
    default = ''
)
args = parser.parse_args()

# Create map of input parameters to create_run_cache parameters
parameter_map = {
    "name": "name",
    "description": "description",
    "cache_s3_location": "cacheS3Location",
    "cache_behavior": "cacheBehavior",
    "cache_bucket_owner_id": "cacheBucketOwnerId",
}

# Open AWS session
session = boto3.Session(profile_name=args.aws_profile)

# Create dictionary of arguments for run cache
run_cache_args = {}
for arg in vars(args):
    if arg in parameter_map:
        if getattr(args, arg) != "":
            run_cache_args[parameter_map.get(arg, arg)] = getattr(args, arg)
# Add tags to run cache arguments
run_cache_args['tags'] = { "project-number": args.charge_code}
# Add request ID to run cache arguments
run_cache_args['requestId'] = "{}_{}".format(args.name if args.name else "run_cache", str(datetime.now().timestamp()))

# Create run cache
omics = session.client('omics')
try:
    response = omics.create_run_cache(**run_cache_args)
except Exception as e:
    raise SystemExit("Error creating run cache: {}".format(e))

print("Successfully created run cache: {}".format(response.get('id')))
print("ARN: {}".format(response.get('arn')))
print("Status: {}".format(response.get('status')))
