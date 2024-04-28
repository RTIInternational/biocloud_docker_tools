import argparse
import json
import os
import time
import requests

parser = argparse.ArgumentParser()
parser.add_argument(
    '--gvcf_dir',
    help = 'Dir containing gvcf files fromw which to extract variants',
    type = str
)
parser.add_argument(
    '--variant_list',
    help = 'List of variants to extract',
    type = str,
    default = '/data/t1dgrs2_hg19_variants.tsv'
)
parser.add_argument(
    '--genedx_manifest',
    help = 'GeneDx manifest file',
    type = str,
    default = '/data/t1dgrs2_hg19_variants.tsv'
)
parser.add_argument(
    '--out_dir',
    help = 'Output directory',
    type = str
)
parser.add_argument(
    '--working_dir',
    help = 'Working directory',
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
    default = 25,
    type = int
)
parser.add_argument(
    '--ref_bfile',
    help = 'Reference samples to merge with test sample',
    type = str,
    default = '/home/merge-shared-folder/t1dgrs2/pipeline_files/ref_bfile/t1dgrs2_ref'
)
parser.add_argument(
    '--control_dir',
    help = 'Directory containing the gvcfs for control samples',
    type = str,
    default = '/home/merge-shared-folder/t1dgrs2/pipeline_files/control_gvcfs/'
)
args = parser.parse_args()

gvcf_dir = args.gvcf_dir if (args.gvcf_dir[-1] == "/") else (args.gvcf_dir + "/")
os.system("mkdir -p {}".format(gvcf_dir))
out_dir = args.out_dir if (args.out_dir[-1] == "/") else (args.out_dir + "/")
os.system("mkdir -p {}".format(out_dir))
working_dir = args.working_dir if (args.working_dir[-1] == "/") else (args.working_dir + "/")
os.system("mkdir -p {}".format(working_dir))
control_dir = args.control_dir if (args.control_dir[-1] == "/") else (args.control_dir + "/")
os.system("mkdir -p {}".format(control_dir))

# Get a list of all files in the directory
files = os.listdir(gvcf_dir) + os.listdir(control_dir)

# Function to get the number of running workflows
def get_running_workflows():
    response = requests.get(args.argo_api_url)
    data = response.json()

    if 'items' not in data or data['items'] is None:
        return 0

    workflows = data['items']
    running_workflows = [wf for wf in workflows if 'phase' not in wf['status'] or wf['status']['phase'] == 'Running']
    return len(running_workflows)

# Loop over all files
for file in files:
    if "gvcf.gz" not in file:
        continue
    if "md5" in file or "tbi" in file:
        continue

    file_id = file.split(".")[0]
    # Wait until the number of running workflows is less than max simultaneous jobs
    while get_running_workflows() >= args.simultaneous_jobs:
        time.sleep(30)

    # Create output dir for sample
    sample_out_dir = "{}{}".format(out_dir, file_id)
    if not os.path.exists(sample_out_dir):
        os.makedirs(sample_out_dir)
    
    # Create working dir for sample
    sample_working_dir = "{}{}".format(working_dir, file_id)
    if not os.path.exists(sample_working_dir):
        os.makedirs(sample_working_dir)
    
    # Create workflow args for gvcf file
    wf_arguments = {
        "working_dir": sample_working_dir,
        "out_prefix": "{}/{}".format(sample_out_dir, file_id),
        "gvcf": gvcf_dir + file,
        "sample_id": file_id,
        "variant_list": args.variant_list,
        "gene_dx_manifest": args.genedx_manifest,
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
                            "value": "t1dgrs2_pipeline_sample"
                        },
                        {
                            "name": "wf_arguments",
                            "value": file_wf_arguments
                        }
                    ]
                },
                "workflowTemplateRef": {
                    "name": "t1dgrs2-pipeline"
                }
            }
        }
    }

    headers = {'Content-Type': 'application/json'}
    print(f"Starting file:{file_id}")
    response = requests.post(args.argo_api_url, headers=headers, data=json.dumps(workflow))
