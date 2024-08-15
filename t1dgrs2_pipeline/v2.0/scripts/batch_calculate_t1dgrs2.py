import argparse
import json
import os
import time
import requests
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    '--gvcf_dir',
    required = True,
    help = 'Dir containing gvcf files fromw which to extract variants',
    type = str
)
parser.add_argument(
    '--genedx_manifest',
    required = True,
    help = 'GeneDx manifest file',
    type = str
)
parser.add_argument(
    '--output_dir',
    required = True,
    help = 'Output directory',
    type = str
)
parser.add_argument(
    '--working_dir',
    required = True,
    help = 'Working directory',
    type = str
)
parser.add_argument(
    '--ref_bfile',
    required = True,
    help = 'Reference samples to merge with test sample',
    type = str
)
parser.add_argument(
    '--argo_api_url',
    required = False,
    help = 'URL for ARGO API',
    default = 'http://argo-early-check-rs-1-server:2746/api/v1/workflows/early-check-rs-1',
    type = str
)
parser.add_argument(
    '--simultaneous_jobs',
    required = False,
    help = '# of simultaneous jobs',
    default = 25,
    type = int
)
parser.add_argument(
    '--control_dir',
    required = False,
    help = 'Directory containing the gvcfs for control samples',
    type = str,
    default = ''
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

gvcf_dir = args.gvcf_dir if (args.gvcf_dir[-1] == "/") else (args.gvcf_dir + "/")
os.system("mkdir -p {}".format(gvcf_dir))
output_dir = args.output_dir if (args.output_dir[-1] == "/") else (args.output_dir + "/")
os.system("mkdir -p {}".format(output_dir))
working_dir = args.working_dir if (args.working_dir[-1] == "/") else (args.working_dir + "/")
os.system("mkdir -p {}".format(working_dir))
if args.control_dir:
    control_dir = args.control_dir if (args.control_dir[-1] == "/") else (args.control_dir + "/")
    os.system("mkdir -p {}".format(control_dir))

# Get a list of all gvcf files to process
files = os.listdir(gvcf_dir)
files_with_paths = [gvcf_dir + file for file in files]
files_to_process = dict(zip(files, files_with_paths))
if len(files_to_process) == 0:
    sys.exit("No files to process")

if control_dir:
    control_files = os.listdir(control_dir)
    control_files_with_paths = [control_dir + file for file in control_files]
    control_files_to_process = dict(zip(control_files, control_files_with_paths))
    if len(control_files_to_process) > 0:
        files_to_process = files_to_process | control_files_to_process

# Loop over all files
for file, path in files_to_process.items():
    if "gvcf.gz" not in file:
        continue
    if "md5" in file or "tbi" in file:
        continue

    file_id = file.split(".")[0]
    # Wait until the number of running workflows is less than max simultaneous jobs
    while get_running_workflows() >= args.simultaneous_jobs:
        time.sleep(30)

    # Create output dir for sample
    sample_output_dir = "{}{}/".format(output_dir, file_id)
    if not os.path.exists(sample_output_dir):
        os.makedirs(sample_output_dir)
    
    # Create working dir for sample
    sample_working_dir = "{}{}/".format(working_dir, file_id)
    if not os.path.exists(sample_working_dir):
        os.makedirs(sample_working_dir)
    
    # Create workflow args for gvcf file
    wf_arguments = {
        "working_dir": sample_working_dir,
        "output_dir": sample_output_dir,
        "gvcf": path,
        "sample_id": file_id,
        "genedx_manifest": args.genedx_manifest,
        "pass_only": 0,
        "filter_by_gq": 0,
        "hom_gq_threshold": 99,
        "het_gq_threshold": 48,
        "ref_bfile": args.ref_bfile
    }
    file_wf_arguments = working_dir + file_id + '.json'
    with open(file_wf_arguments, 'w', encoding='utf-8') as f:
        json.dump(wf_arguments, f)
    
    # Submit the workflow for the current file
    generate_name = file_id + "-"
    workflow = {
        "namespace": "early-check-rs-1",
        "serverDryRun": False,
        "workflow": {
            "metadata": {
                "namespace": "early-check-rs-1",
                "generateName": generate_name
            },
            "spec": {
                "arguments": {
                    "parameters": [
                        {
                            "name": "wf_definition",
                            "value": "entrypoint_sample"
                        },
                        {
                            "name": "wf_arguments",
                            "value": file_wf_arguments
                        }
                    ]
                },
                "workflowTemplateRef": {
                    "name": "t1dgrs2-process-sample"
                }
            }
        }
    }

    headers = {'Content-Type': 'application/json'}
    print(f"Starting file: {file_id}")
    response = requests.post(args.argo_api_url, headers=headers, data=json.dumps(workflow))
