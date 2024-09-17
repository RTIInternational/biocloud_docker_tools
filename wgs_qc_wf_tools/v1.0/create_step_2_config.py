import argparse
import json
import boto3
import re
import os
import sys

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
    '--step_1_output_json',
    help = 'S3 path to JSON file containing outputs from Step 1',
    type = str,
    required = True
)
parser.add_argument(
    '--output_dir',
    help = 'Directory for outputting Step 1 outputs and Step 2 config JSON',
    type = str,
    required = True
)
parser.add_argument(
    '--minimum_ancestry_sample_count',
    help = 'Minimum ancestry sample count for running Step 2',
    type = int,
    default = 50,
    required = False
)

args = parser.parse_args()

# Create output directory if doesn't exist
output_dir = args.output_dir if (args.output_dir[-1] == "/") else (args.output_dir + "/")
os.system("mkdir -p {}".format(output_dir))

# Retrieve Step 1 outputs json from S3
result = re.search('s3://(.+?)/(.+)', args.step_1_output_json)
if result:
    step_1_output_bucket = result.group(1)
    step_1_output_json = result.group(2)
    local_step_1_output_json = '{}step_1_outputs.json'.format(output_dir)
    session = boto3.Session(aws_access_key_id=args.aws_access_key_id, aws_secret_access_key=args.aws_secret_access_key)
    s3 = session.resource('s3')
    my_bucket = s3.Bucket(step_1_output_bucket)
    my_bucket.download_file(step_1_output_json, local_step_1_output_json)
else:
    print("Invalid path provided for step_1_output_json")
    sys.exit(1)

# Read Step 1 outputs
with open(local_step_1_output_json) as f:
    step_1_outputs = json.load(f)

# Generate step 2 config for each ancestry with at least the minimum required sample count
for ancestry_index in range(len(step_1_outputs['wgs_qc_wf_step_1.counts']['sample_ancestries'])):
    if step_1_outputs['wgs_qc_wf_step_1.counts']['sample_ancestries'][ancestry_index]['right'] > args.minimum_ancestry_sample_count:
        step_2_config = step_1_outputs['wgs_qc_wf_step_1.step_2_parameters'].copy()
        step_2_config['ancestry_samples'] = step_1_outputs['wgs_qc_wf_step_1.sample_lists']['ancestries'][ancestry_index]['right']
        step_2_config['output_basename'] = '{}_{}'.format(step_2_config['output_basename'], step_1_outputs['wgs_qc_wf_step_1.sample_lists']['ancestries'][ancestry_index]['left'])
        step_2_config_file = '{}wgs_qc_wf_step_2_config_{}.json'.format(output_dir, step_1_outputs['wgs_qc_wf_step_1.sample_lists']['ancestries'][ancestry_index]['left'])
        with open(step_2_config_file, 'w') as f:
            json.dump(step_2_config, f)

