import argparse
import os
import boto3

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--genome_build',
    help='Genome build of reference files to retrieve',
    type = str,
    default ='grch37',
    choices = ['grch37', 'grch38']
)
parser.add_argument(
    '--ref_panel',
    help='Reference panel to retrieve',
    type = str,
    default = '1000g',
    choices = ['1000g']
)
parser.add_argument(
    '--aws_access_key',
    help='AWS access key for accessing S3',
    type = str
)
parser.add_argument(
    '--aws_secret_access_key',
    help='AWS secret access key for accessing S3',
    type = str
)
parser.add_argument(
    '--target_dir',
    help='Directory to which ref files should be retrieved',
    type = str
)
args = parser.parse_args()

target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")
os.system("mkdir -p {}".format(target_dir))

source_bucket = 'rti-bioinformatics-resources'
source_dirs = {}
source_dirs['1000g'] = {}
source_dirs['1000g']['grch37'] = 'wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch37/'
source_dirs['1000g']['grch38'] = 'wf_inputs/biocloud_docker_tools/ancestry_pipeline/v1/grch38/'

# Connect to S3
session = boto3.Session(aws_access_key_id=args.aws_access_key, aws_secret_access_key=args.aws_secret_access_key)
s3 = session.resource('s3')
my_bucket = s3.Bucket(source_bucket)
client = session.client('s3')

response = client.list_objects_v2(
    Bucket = source_bucket,
    Prefix = source_dirs[args.ref_panel][args.genome_build]
)

for o in response['Contents']:
    key = o['Key']
    if key[-1] == '/':
        continue
    file_name = key.split("/")[-1]
    target_file = target_dir + file_name
    print("Downloading {} to {}".format(key, target_file))
    my_bucket.download_file(key, target_file)
