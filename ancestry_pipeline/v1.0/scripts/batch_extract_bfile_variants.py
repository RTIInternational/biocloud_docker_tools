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
    '--bfile_list',
    required = True,
    help = 'Dir containing gvcf files from which to extract variants',
    type = str
)
parser.add_argument(
    '--ref_prefix',
    required = True,
    help = 'Reference variant list',
    type = str
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
    default = 'munge-extract-ref-variants-from-bfile',
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

# Get a list of all bfiles to process
with open(args.bfile_list, 'r') as file:
    files_to_process = file.readlines()
files_to_process = [file.strip() for file in files_to_process if file.strip()]
if len(files_to_process) == 0:
    sys.exit("No files to process")

# Set file name for plink merge list
file_plink_merge_list = "{}plink_merge_list.txt".format(output_dir)

# Loop over all files
for bfile in files_to_process:
    # Wait until the number of running workflows is less than max simultaneous jobs
    while get_running_workflows() >= args.simultaneous_jobs:
        time.sleep(30)

    # Create output dir for sample
    bfile_basename = os.path.basename(bfile)
    bfile_out_dir = "{}{}/".format(output_dir, bfile_basename)
    if not os.path.exists(bfile_out_dir):
        os.makedirs(bfile_out_dir)

    # Create workflow args for bfile file
    bfile_out_prefix = "{}{}".format(bfile_out_dir, bfile_basename)
    wf_arguments = {
        "output_dir": bfile_out_dir,
        "bed": "{}.bed".format(bfile),
        "bim": "{}.bim".format(bfile),
        "fam": "{}.fam".format(bfile),
        "ref_prefix": args.ref_prefix,
        "out_prefix": bfile_out_prefix
    }
    file_wf_arguments = "{}.json".format(bfile_out_prefix)
    with open(file_wf_arguments, 'w', encoding='utf-8') as f:
        json.dump(wf_arguments, f)
    
    # Submit the workflow for the current file
    generate_name = bfile_basename.lower().replace('_', '').replace('.', '') + "-"
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

    # Write sample plink output prefix to merge list
    with open(file_plink_merge_list, 'a') as f:
        f.write("{}\n".format(bfile_out_prefix))
