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
    '--aws_profile',
    help='AWS profile to use for credentials',
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
    '--workflow_version_name',
    help='Name of workflow version to run',
    type = str,
    required = False,
    default = ''
)
parser.add_argument(
    '--name',
    help='A name for the run',
    type = str,
    required = True
)
parser.add_argument(
    '--cache_id',
    help='ID of cache to use for the run',
    type = str,
    required = False,
    default = ''
)
parser.add_argument(
    '--cache_behavior',
    help='Cache behavior for the run',
    type = str,
    required = False,
    choices = ['', 'CACHE_ON_FAILURE', 'CACHE_ALWAYS'],
    default = ''
)
parser.add_argument(
    '--parameters',
    help='JSON file with run parameters',
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

# Create map of input parameters to start_run parameters
parameter_map = {
    "workflow_id": "workflowId",
    "workflow_version_name": "workflowVersionName",
    "name": "name",
    "cache_id": "cacheId",
    "cache_behavior": "cacheBehavior",
    "parameters": "parameters",
    "output_uri": "outputUri",
    "tags": "tags",
    "workflow_type": "workflowType",
    "priority": "priority",
    "storage_type": "storageType",
    "storage_capacity": "storageCapacity",
    "log_level": "logLevel",
    "retention_mode": "retentionMode",
}

# Open AWS session
session = boto3.Session(profile_name=args.aws_profile)

# Create dictionary of arguments for run
run_args = {}
for arg in vars(args):
    if arg in parameter_map:
        if getattr(args, arg) != "":
            run_args[parameter_map.get(arg, arg)] = getattr(args, arg)
# Add parameters to run arguments
with open(args.parameters) as f:
    parameters = json.load(f)
run_args['parameters'] = parameters
# Add tags to run arguments
run_args['tags'] = { "project-number": args.charge_code}
# Add request ID to run arguments
run_args['requestId'] = "{}_{}".format(args.name, str(datetime.now().timestamp()))
# Add role ARN to run arguments
client = session.client("sts")
account_id = client.get_caller_identity()["Account"]
role_arn = "arn:aws:iam::{}:role/OmicsWorkflow".format(account_id)
run_args['roleArn'] = role_arn

# Start run
omics = session.client('omics')
response = omics.start_run(**run_args)

with open("{}{}_metadata.json".format(run_metadata_output_dir, args.name), 'w', encoding='utf-8') as f:
    json.dump(response, f)
