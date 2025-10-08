import argparse
import boto3
import json
import os
from healthomics_utils import get_run_metadata

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_profile',
    help='AWS profile to use for credentials',
    type = str,
    required = True
)
parser.add_argument(
    '--run_id',
    help='Healthomics ID of run',
    type = str,
    required = True
)
parser.add_argument(
    '--target_dir',
    help='Directory where run outputs will be saved',
    type = str,
    required = True
)
args = parser.parse_args()

def traverse(o, s3_client, target_dir):
    tree_types=(tuple, dict)
    for key in o:
        if isinstance(o[key], tree_types):
            new_target_dir = "{}{}/".format(target_dir, key)
            os.system("mkdir -p {}".format(new_target_dir))
            for subkey in o[key]:
                traverse(o[key][subkey], s3_client, new_target_dir)
        elif isinstance(o[key], list):
            new_target_dir = "{}{}/".format(target_dir, key)
            os.system("mkdir -p {}".format(new_target_dir))
            for item in o[key]:
                if (str(item)[0:2] == "s3"):
                    file_path = item.replace("s3://", "")
                    path_parts = file_path.split("/")
                    s3_bucket = path_parts[0]
                    s3_key = "/".join(path_parts[1:])
                    file_name = s3_key.split("/")[-1]
                    s3_client.download_file(s3_bucket, s3_key, os.path.join(target_dir, file_name))
                    print("Downloaded {} to {}".format(s3_key, os.path.join(target_dir, file_name)))
        else:
            if (str(o[key])[0:2] == "s3"):
                file_path = o[key].replace("s3://", "")
                path_parts = file_path.split("/")
                s3_bucket = path_parts[0]
                s3_key = "/".join(path_parts[1:])
                file_name = s3_key.split("/")[-1]
                s3_client.download_file(s3_bucket, s3_key, os.path.join(target_dir, file_name))
                print("Downloaded {} to {}".format(s3_key, os.path.join(target_dir, file_name)))

target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")
os.system("mkdir -p {}".format(target_dir))

# Get run metadata
run_metadata = get_run_metadata(args.aws_profile, args.run_id)
if not run_metadata:
    print("No run found with ID {}".format(args.run_id))
    exit(1)

if 'outputUri' not in run_metadata:
    print("No outputUri found for run {}, cannot retrieve results".format(args.run_id))
    exit(1)

# Open AWS session
session = boto3.Session(profile_name=args.aws_profile)
s3_client = session.client("s3")

# Retrieve outputs.json
source_bucket = run_metadata['outputUri'].replace("s3://", "").split("/")[0]
source_path = "{}/logs/outputs.json".format(args.run_id)
target_path = "{}{}_outputs.json".format(target_dir, args.run_id)
s3_client.download_file(source_bucket, source_path, target_path)

# Read outputs.json
with open(target_path) as f:
    outputs = json.load(f)

# Retrieve all output files
traverse(outputs, s3_client, target_dir)
