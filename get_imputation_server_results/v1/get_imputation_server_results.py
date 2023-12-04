import argparse
import json
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--token",
    help="Authentication token for API",
    type = str
)
parser.add_argument(
    "--job_id_json",
    help="File containing job ID",
    type = str
)
parser.add_argument(
    "--out_dir",
    help="Output directory",
    type = str
)
parser.add_argument(
    "--server",
    help="Server used for imputation",
    type = str,
    choices = ["mis", "topmed"]
)
args = parser.parse_args()

out_dir = args.out_dir if (args.out_dir[-1] == "/") else (args.out_dir + "/")

with open(args.job_id_json) as f:
    job_id_json = json.load(f)

# Get job details
job_details_endpoint = ''
results_endpoint = ''
if args.server == 'mis':
    job_details_endpoint = 'https://imputationserver.sph.umich.edu/api/v2/jobs/' + job_id_json['id']
    results_endpoint = 'https://imputationserver.sph.umich.edu/share/results/'
elif args.server == 'topmed':
    job_details_endpoint = 'https://imputation.biodatacatalyst.nhlbi.nih.gov/api/v2/jobs/' + job_id_json['id']
    results_endpoint = 'https://imputation.biodatacatalyst.nhlbi.nih.gov/share/results/'

job_details_json = out_dir + 'job_details.json'
get_job_details_cmd = "curl -H \"X-Auth-Token: {}\" {} > {}".format(args.token, job_details_endpoint, job_details_json)
os.system(get_job_details_cmd)

# Transfer outputs
with open(job_details_json) as f:
    outputs = json.load(f)

for output_category in outputs['outputParams']:
    for file in output_category['files']:
        file_download_cmd = "wget -P {} {}{}/{}".format(out_dir, results_endpoint, file['hash'], file['name'])
        os.system(file_download_cmd)
