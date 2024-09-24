import argparse
import json
import os
import time
import requests
import sys
import re

parser = argparse.ArgumentParser()
parser.add_argument(
    '--working_dir',
    required = True,
    help = 'Working directory',
    type = str
)
parser.add_argument(
    '--output_dir',
    required = True,
    help = 'Output directory',
    type = str
)
parser.add_argument(
    '--gvcf_dir',
    required = True,
    help = 'Dir containing gvcf files from which to extract variants',
    type = str
)
parser.add_argument(
    '--variant_list',
    required = True,
    help = 'List of variants to extract',
    type = str
)
parser.add_argument(
    '--hla_variants_file',
    required = True,
    help = 'File listing HLA variants used for DQ imputation',
    type = str
)
parser.add_argument(
    '--non_hla_variants_file',
    required = True,
    help = 'File listing HLA variants not used for DQ imputation',
    type = str
)
parser.add_argument(
    '--sequencing_provider',
    required = False,
    help = 'Sequencing provider',
    default = 'revvity',
    type = str,
    choices = ['revvity', 'genedx']
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
    default = 50,
    type = int
)
parser.add_argument(
    '--pass_only',
    required = False,
    help = 'Limit extraction to variants designated PASS',
    default = 0,
    type = int
)
parser.add_argument(
    '--filter_by_gq',
    required = False,
    help = 'Filter variatns by GQ',
    default = 0,
    type = int
)
parser.add_argument(
    '--hom_gq_threshold',
    required = False,
    help = 'GQ threshold for homozygous variants',
    default = 99,
    type = int
)
parser.add_argument(
    '--het_gq_threshold',
    required = False,
    help = 'GQ threshold for heterozygous variants',
    default = 48,
    type = int
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

# Get a list of all gvcf files to process
files = os.listdir(gvcf_dir)
files_with_paths = [gvcf_dir + file for file in files]
files_to_process = dict(zip(files, files_with_paths))
if len(files_to_process) == 0:
    sys.exit("No files to process")

# Loop over all files
file_plink_merge_list = "{}plink_merge_list.txt".format(output_dir)
file_missingness_merge_list = "{}missingness_merge_list.txt".format(output_dir)
for file, path in files_to_process.items():
    if "gvcf.gz" not in file:
        continue
    if "md5" in file or "tbi" in file:
        continue

    if args.sequencing_provider == 'revvity':
        result = re.search(r'^\S+\-(\d+)_\d+-WGS.+\.hard-filtered.gvcf.gz$', file)
    elif args.sequencing_provider == 'genedx':
        result = re.search(r'^(\d+).hard-filtered.gvcf.gz$', file)
    if result:
        sample_id = result.group(1)

        # Wait until the number of running workflows is less than max simultaneous jobs
        while get_running_workflows() >= args.simultaneous_jobs:
            time.sleep(30)

        # Create output dir for sample
        sample_output_dir = "{}{}/".format(output_dir, sample_id)
        if not os.path.exists(sample_output_dir):
            os.makedirs(sample_output_dir)
        
        # Create working dir for sample
        sample_working_dir = "{}{}/".format(working_dir, sample_id)
        if not os.path.exists(sample_working_dir):
            os.makedirs(sample_working_dir)

        # Create workflow args for gvcf file
        wf_arguments = {
            "working_dir": sample_working_dir,
            "output_dir": sample_output_dir,
            "sample_id": sample_id,
            "gvcf": path,
            "variant_list": args.variant_list,
            "hla_variants_file": args.hla_variants_file,
            "non_hla_variants_file": args.non_hla_variants_file,
            "pass_only": args.pass_only,
            "filter_by_gq": args.filter_by_gq,
            "hom_gq_threshold": args.hom_gq_threshold,
            "het_gq_threshold": args.het_gq_threshold
        }
        file_wf_arguments = working_dir + sample_id + '.json'
        with open(file_wf_arguments, 'w', encoding='utf-8') as f:
            json.dump(wf_arguments, f)
        
        # Submit the workflow for the current file
        generate_name = sample_id + "-"
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
                                "value": "entrypoint_extract_gvcf_variants"
                            },
                            {
                                "name": "wf_arguments",
                                "value": file_wf_arguments
                            }
                        ]
                    },
                    "workflowTemplateRef": {
                        "name": "t1dgrs2-v2-extract-variants"
                    }
                }
            }
        }

        headers = {'Content-Type': 'application/json'}
        print(f"Starting file: {file}")
        response = requests.post(args.argo_api_url, headers=headers, data=json.dumps(workflow))

        # Write sample plink output prefix to merge list
        with open(file_plink_merge_list, 'a') as f:
            f.write("{}{}/{}\n".format(sample_output_dir, "convert_vcf_to_bfile", sample_id))

        # Write sample missing summary tsv path to list
        with open(file_missingness_merge_list, 'a') as f:
            f.write("{}{}/{}_missing_summary.tsv\n".format(sample_output_dir, "extract_gvcf_variants", sample_id))
