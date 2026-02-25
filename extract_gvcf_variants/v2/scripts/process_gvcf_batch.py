import argparse
import json
import os
import time
import requests
import sys
import re

parser = argparse.ArgumentParser()
parser.add_argument(
    '--output_dir',
    required = True,
    help = 'Output directory',
    type = str
)
parser.add_argument(
    '--gvcf_list',
    required = True,
    help = 'Dir containing gvcf files from which to extract variants',
    type = str
)
parser.add_argument(
    '--bim',
    required = True,
    help = 'Reference variant list',
    type = str
)
parser.add_argument(
    '--include_homozygous_ref',
    required = False,
    help = 'Include homozygous reference variants',
    type = int,
    default = 1
)
parser.add_argument(
    '--filter_by_qual',
    required = False,
    help = 'Filter variants by quality',
    type = int,
    default = 0
)
parser.add_argument(
    '--filter_by_gq',
    required = False,
    help = 'Filter variants by genotype quality',
    type = int,
    default = 0
)
parser.add_argument(
    '--hom_gq_threshold',
    required = False,
    help = 'Genotype quality threshold for filtering homozygous variants',
    type = int,
    default = 99
)
parser.add_argument(
    '--het_gq_threshold',
    required = False,
    help = 'Genotype quality threshold for filtering heterozygous variants',
    type = int,
    default = 48
)
parser.add_argument(
    '--argo_api_url',
    help = 'URL for ARGO API',
    default = 'http://argo-early-check-rs-1-server:2746/api/v1/workflows/early-check-rs-1',
    type = str
)
parser.add_argument(
    '--simultaneous_jobs',
    help = '# of simultaneous jobs',
    default = 50,
    type = int
)
parser.add_argument(
    '--workflow_template',
    help = 'Workflow template to use',
    default = 'ancestry',
    type = str
)
parser.add_argument(
    '--entrypoint',
    help = 'Entrypoint to use',
    default = 'munge-extract-ref-variants-from-gvcf',
    type = str
)
args = parser.parse_args()

# Function to get the number of running workflows
def get_running_workflows():
    response = requests.get(args.argo_api_url)
    data = response.json()
    if 'items' not in data or data['items'] is None:
        return 0
    workflows = data['items']
    running_workflows = [wf for wf in workflows if 'phase' not in wf['status'] or wf['status']['phase'] == 'Running']
    return len(running_workflows)

output_dir = args.output_dir if (args.output_dir[-1] == "/") else (args.output_dir + "/")
os.system("mkdir -p {}".format(output_dir))

# Get a list of all gvcfs to process
with open(args.gvcf_list, 'r') as file:
    files_to_process = file.readlines()
files_to_process = [file.strip() for file in files_to_process if file.strip()]
if len(files_to_process) == 0:
    sys.exit("No files to process")

# Loop over all files
for gvcf in files_to_process:
    # Wait until the number of running workflows is less than max simultaneous jobs
    while get_running_workflows() >= args.simultaneous_jobs:
        time.sleep(30)

    # Create output dir for sample
    gvcf_basename = os.path.basename(gvcf)
    sample_id = re.sub(r'.hard-filtered.gvcf.*', '', gvcf_basename)
    match = re.match(r'^\S+-(\d+)_\d+-WGS', sample_id)
    if match:
        sample_id = match.group(1)

    out_dir = "{}{}/".format(output_dir, sample_id)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    # Create workflow args for gvcf file
    out_prefix = "{}{}".format(out_dir, sample_id)
    wf_arguments = {
        "output_dir": out_dir,
        "file_in_gvcf": gvcf,
        "file_in_bim": args.bim,
        "sample_id": sample_id,
        "include_homozygous_ref": args.include_homozygous_ref,
        "filter_by_qual": args.filter_by_qual,
        "filter_by_gq": args.filter_by_gq,
        "hom_gq_threshold": args.hom_gq_threshold,
        "het_gq_threshold": args.het_gq_threshold
    }
    file_wf_arguments = "{}.json".format(out_prefix)
    with open(file_wf_arguments, 'w', encoding='utf-8') as f:
        json.dump(wf_arguments, f)
    
    # Submit the workflow for the current file
    generate_name = gvcf_basename.lower().replace('_', '').replace('.', '') + "-"
    workflow = {
        "namespace": "early-check-rs-1",
        "serverDryRun": False,
        "workflow": {
            "metadata": {
                "namespace": "early-check-rs-1",
                "generateName": generate_name
            },
            "spec": {
                "entrypoint": args.entrypoint,
                "arguments": {
                    "parameters": [
                        {
                            "name": "wf_arguments",
                            "value": file_wf_arguments
                        }
                    ]
                },
                "workflowTemplateRef": {
                    "name": args.workflow_template
                }
            }
        }
    }

    headers = {'Content-Type': 'application/json'}
    print(f"Starting file: {file}")
    response = requests.post(args.argo_api_url, headers=headers, data=json.dumps(workflow))
    if response.status_code != 200:
        print(f"Error submitting workflow for file {file}: {response.text}")
    else:
        print(f"Workflow submitted for file {file}")
