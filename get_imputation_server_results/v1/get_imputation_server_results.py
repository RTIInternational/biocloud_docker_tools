import argparse
import json
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    "--token",
    help="Security token for accessing results",
    type = str
)
parser.add_argument(
    "--job_id_json",
    help="JSON file containing id as key",
    type = str
)
parser.add_argument(
    "--out_dir",
    help="Directory in which to place the outputs",
    type = str
)
parser.add_argument(
    "--server",
    help="Imputation server to retrieve results from",
    type = str.lower,
    choices=["topmed", "mis"]
)
args = parser.parse_args()

def traverse(o, tree_types=(list, tuple)):
    if isinstance(o, tree_types):
        for value in o:
            for subvalue in traverse(value, tree_types):
                yield subvalue
    else:
        yield o

out_dir = args.out_dir if (args.out_dir[-1] == "/") else (args.out_dir + "/")
os.chdir(out_dir)
server_paths = {
    'topmed': 'https://imputation.biodatacatalyst.nhlbi.nih.gov/',
    'mis': 'https://imputationserver.sph.umich.edu/'
}

# Get job ID
with open(args.job_id_json) as f:
    job_id_json = json.load(f)

# Get outputs json
outputs_json = out_dir + "outputs.json"
get_outputs_json_cmd = "curl -H \"X-Auth-Token: {}\" {}api/v2/jobs/{} > {}".format(args.token, server_paths[args.server], job_id_json['id'], outputs_json)
os.system(get_outputs_json_cmd)

# Transfer outputs
with open(outputs_json) as f:
    outputs = json.load(f)

for output_param in outputs["outputParams"]:
    get_files_cmd = "curl -sL {}get/{}/{} | bash".format(server_paths[args.server], output_param['id'], output_param['hash'])
    print ('Retrieving ' + output_param['description'])
    os.system(get_files_cmd)
