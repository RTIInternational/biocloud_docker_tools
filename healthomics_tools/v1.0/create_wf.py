import argparse
import boto3
import json
from datetime import datetime
import os
from pathlib import Path
import io
import zipfile
from git import Repo
import sys

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_access_key_id',
    help = 'Access key ID for AWS',
    type = str,
    required = True
)
parser.add_argument(
    '--aws_secret_access_key',
    help = 'Secret access key for AWS',
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
    '--repo_dir',
    help = 'Base directory of repository containing workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--main',
    help = 'Path to main wdl file for workflow',
    type = str,
    required = True
)
parser.add_argument(
    '--parameter_template',
    help = 'JSON containing workflow parameters',
    type = str,
    required = True
)
parser.add_argument(
    '--name',
    help = 'Name of wf to be created',
    type = str,
    required = True
)
parser.add_argument(
    '--description',
    help = 'Description of wf to be created',
    type = str,
    required = True
)
parser.add_argument(
    '--engine',
    help = 'Engine to use for workflow',
    type = str,
    default = 'WDL',
    choices = ['WDL', 'NEXTFLOW', 'CWL'],
    required = False
)
parser.add_argument(
    '--storage_capacity',
    help = 'Storage capacity for workflow',
    type = int,
    default = 2000,
    required = False
)

args = parser.parse_args()

def get_wf_dependencies(repo_dir, wf_path):
    dependencies = []
    wf_dependencies_file = "{}{}".format(repo_dir, wf_path).replace(".wdl", "_dependencies.json")
    with open(wf_dependencies_file) as f:
        wf_dependencies = json.load(f)
    if 'workflows' in wf_dependencies:
        more_dependencies = []
        for sub_wf in wf_dependencies['workflows']:
            dependencies.append("{}{}".format(repo_dir, sub_wf))
            dependencies = dependencies + get_wf_dependencies(repo_dir, sub_wf)
    if 'wdl_tools' in wf_dependencies:
        for wdl_tool in wf_dependencies['wdl_tools']:
            dependencies.append("{}{}".format(repo_dir, wdl_tool))
    if 'structs' in wf_dependencies:
        for struct in wf_dependencies['structs']:
            dependencies.append("{}{}".format(repo_dir, struct))
    dependencies = list(set(dependencies))
    return dependencies


repo_dir = args.repo_dir if (args.repo_dir[-1] == "/") else (args.repo_dir + "/")
main_wdl_repo_path = args.main.replace(repo_dir, '')
main_wdl = os.path.basename(args.main)

# Get repo hash
repo = Repo(repo_dir)
git_hash = repo.git.rev_parse(repo.head, short=6)

# Create tags
tags = {
    "git-repo-name": os.path.basename(os.path.normpath(repo_dir)),
    "git-repo-hash": git_hash
}

# Create zip object for wf files
dependencies = get_wf_dependencies(repo_dir, main_wdl_repo_path)
dependencies.append("{}{}".format(repo_dir, main_wdl_repo_path))
zip_buffer = io.BytesIO()
with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
    for file in dependencies:
        zip_file.write(file, os.path.basename(file))
wf_def = zip_buffer.getvalue()

# Read parameter template
with open(args.parameter_template) as f:
    wf_params = json.load(f)

# Create Healthomics session and create wf
session = boto3.Session(aws_access_key_id=args.aws_access_key_id, aws_secret_access_key=args.aws_secret_access_key, region_name=args.aws_region_name)
omics = session.client('omics')
request_id = args.name + str(datetime.now().timestamp())
response = omics.create_workflow(
    name=args.name,
    description=args.description,
    engine=args.engine,
    definitionZip=wf_def,
    main=main_wdl,
    parameterTemplate=wf_params,
    storageCapacity=args.storage_capacity,
    requestId=request_id,
    tags=tags
)
