import argparse
import json
import subprocess
import re
import sys
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--wf_config',
    help='JSON Config file for running the wf',
    type = str
)
parser.add_argument(
    '--wf_arguments',
    help='JSON file with wf arguments',
    type = str
)
args = parser.parse_args()


def create_wf_vars (config):
    wf_vars = {}
    for input in config['inputs']:
        wf_vars["inputs.{}".format(input)] = config['inputs'][input]['default']
    for output in config['outputs']:
        wf_vars["outputs.{}".format(output)] = None
    
    return wf_vars


def process_vars (template, wf_vars):
    out_str = template
    result = re.findall(r"<(\S+?)>", template)
    for var in result:
        out_str = out_str.replace('<' + var + '>', str(wf_vars[var]))

    return out_str


def create_task_vars (config, wf_vars):
    for key in ['inputs', 'outputs']:
        vars = config[key]
        for var in vars:
            value = process_vars(vars[var]['value'], wf_vars)
            wf_vars["tasks.{}.{}.{}".format(config['name'], key, var)] = value
    
    return wf_vars


def process_wf_inputs (args, wf_vars):
    for parameter in args:
        key = "inputs.{}".format(parameter)
        if key in wf_vars:
            wf_vars[key] = args[parameter]
        else:
            sys.exit("Workflow parameter does not exist: {}".format(parameter))

    return wf_vars


def prepare_cmd (cmd_template, wf_vars):
    processed_cmd = cmd_template
    for i in range(len(cmd_template)):
        processed_cmd[i] = process_vars(cmd_template[i], wf_vars)

    return processed_cmd


class log_stdout():
    def __init__(self, logfile):
        self.stdout = sys.stdout
        self.log = open(logfile, 'w')

    def write(self, text):
            self.stdout.write(text)
            self.log.write(text)
            self.log.flush()

    def close(self):
            self.stdout.close()
            self.log.close()


# Read wf config
with open(args.wf_config) as f:
    wf_config = json.load(f)

# Create dict of wf variables
wf_vars = create_wf_vars(wf_config)

# Read wf arguments
with open(args.wf_arguments) as f:
    wf_args = json.load(f)

# Set general wf vars
wf_vars = process_wf_inputs(wf_args, wf_vars)
wf_vars['inputs.final_file_location'] = wf_vars['inputs.final_file_location'] if (wf_vars['inputs.final_file_location'][-1] == "/") else (wf_vars['inputs.final_file_location'] + "/")

# Open log file
os.system("mkdir -p {}".format(wf_vars['inputs.final_file_location']))
wf_log = "{}{}.log".format(wf_vars['inputs.final_file_location'], wf_config['name'])
sys.stdout = log_stdout(wf_log)
print("Initializing workflow {}\n".format(wf_config['name']))

# Run wf
for task in wf_config['tasks']:
    wf_vars = create_task_vars(task, wf_vars)
    if task['active']:
        print("Running task {}".format(task['name']))
        os.system("mkdir -p {}{}".format(wf_vars['inputs.final_file_location'], task['name']))
        task_log = "{}{}/{}.log".format(wf_vars['inputs.final_file_location'], task['name'], task['name'])
        f = open(task_log, 'w')
        cmd = prepare_cmd(task['cmd'], wf_vars)
        f.write("\n".join(str(item) for item in cmd))
        try:
            result = subprocess.run(
                cmd,
                text=True,
                check=True,
                capture_output=True
            )
            f.write(result.stdout + "\n")
            print("Task {} complete\n".format(task['name']))
        except subprocess.CalledProcessError as e:
            if task['kill_wf_on_error']:
                f.write(e.stderr)
                print(e.stderr)
                sys.exit(e.stderr)
            else:
                print("Task {} complete\n".format(task['name']))

        f.close()

    else:
        print("Using cached outputs for task {}\n".format(task['name']))


print("Workflow {} complete".format(wf_config['name']))
