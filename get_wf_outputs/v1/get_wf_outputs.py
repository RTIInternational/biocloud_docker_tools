import argparse
import json
import os

# Get arguments
parser = argparse.ArgumentParser()
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
    "--operation_type",
    help="mv or cp",
    type = str.lower,
    choices=["mv", "cp"]
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

# Get job ID
with open(args.job_id_json) as f:
    job_id_json = json.load(f)

# Get outputs json
outputs_json = out_dir + "outputs.json"
get_outputs_cmd = "curl -X GET \"http://localhost:8000/api/workflows/v1/{}/outputs\" > {}".format(job_id_json['id'], outputs_json)
os.system(get_outputs_cmd)

# Transfer outputs
with open(outputs_json) as f:
    outputs = json.load(f)

for key in outputs["outputs"]:
    if (type(outputs["outputs"][key]) == list):
        for value in traverse(outputs["outputs"][key]):
            if (str(value)[0:2] == "s3"):
                os.system("aws s3 {} {} {}".format(args.operation_type, value, out_dir))
    else:
        if (str(outputs["outputs"][key])[0:2] == "s3"):
            os.system("aws s3 {} {} {}".format(args.operation_type, outputs["outputs"][key], out_dir))
                      
