import argparse
import boto3
from datetime import datetime
import json
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--charge_code',
    help='Charge code to assign to run',
    type = str,
    required = True
)
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
parser.add_argument(
    '--workflow_id',
    help='Healthomics ID of workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--parameters',
    help='JSON file with run parameters',
    type = str,
    required = True
)
parser.add_argument(
    '--name',
    help='A name for the run',
    type = str,
    required = True
)
parser.add_argument(
    '--output_uri',
    help='S3 path for run outputs',
    type = str,
    required = True
)
parser.add_argument(
    '--run_metadata_output_dir',
    help='Directory where metadata about the run will be output',
    type = str,
    required = True
)
parser.add_argument(
    '--workflow_type',
    help='Workflow type for run',
    type = str,
    default = "PRIVATE",
    required = False,
    choices = ['PRIVATE', 'PUBLIC']
)
parser.add_argument(
    '--priority',
    help='Priority for the run',
    type = int,
    default = 100,
    required = False
)
parser.add_argument(
    '--storage_type',
    help='Storage type for the run',
    type = str,
    default = "STATIC",
    required = False,
    choices = ['STATIC', 'DYNAMIC']
)
parser.add_argument(
    '--storage_capacity',
    help='Storage capacity for run in gigabytes',
    type = int,
    default = 2000,
    required = False
)
parser.add_argument(
    '--log_level',
    help='Log level for the run',
    type = str,
    default = "ALL",
    required = False,
    choices = ['OFF', 'FATAL', 'ERROR', 'ALL']
)
parser.add_argument(
    '--retention_mode',
    help='Retention mode for the run',
    type = str,
    default = "RETAIN",
    required = False,
    choices = ['RETAIN', 'REMOVE']
)
args = parser.parse_args()

run_metadata_output_dir = args.run_metadata_output_dir if (args.run_metadata_output_dir[-1] == "/") else (args.run_metadata_output_dir + "/")
os.system("mkdir -p {}".format(run_metadata_output_dir))

# Read wf arguments
with open(args.parameters) as f:
    parameters = json.load(f)

# Create tags for run
tags = { "project-number": args.charge_code}

# Open AWS Healthomics session
session = boto3.Session(aws_access_key_id=args.aws_access_key_id, aws_secret_access_key=args.aws_secret_access_key, region_name=args.aws_region_name)

# Get role ARN
client = session.client("sts")
account_id = client.get_caller_identity()["Account"]
role_arn = "arn:aws:iam::{}:role/OmicsWorkflow".format(account_id)

# Start run
omics = session.client('omics')
request_id = "{}_{}".format(args.name, str(datetime.now().timestamp()))
response = omics.start_run(
    roleArn=role_arn,
    workflowId=args.workflow_id,
    parameters=parameters,
    name=args.name,
    outputUri=args.output_uri,
    tags=tags,
    workflowType=args.workflow_type,
    priority=args.priority,
    storageType=args.storage_type,
    storageCapacity=args.storage_capacity,
    logLevel=args.log_level,
    retentionMode=args.retention_mode,
    requestId=request_id
)

with open("{}{}_metadata.json".format(run_metadata_output_dir, args.name), 'w', encoding='utf-8') as f:
    json.dump(response, f)

