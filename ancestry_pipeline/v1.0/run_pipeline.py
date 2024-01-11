import argparse
import json
import subprocess
import re
import sys
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--wf_definition',
    help='JSON file containing the wf definition',
    type = str
)
parser.add_argument(
    '--wf_tasks',
    help='JSON file with task definitions',
    type = str
)
parser.add_argument(
    '--wf_arguments',
    help='JSON file with wf arguments',
    type = str
)
parser.add_argument(
    '--use_cached_results',
    help='Use cached results if available',
    action='store_true'
)
args = parser.parse_args()


def set_wf_inputs (wf_def, wf_args):
    wf_vars = {}
    for input in wf_def['inputs']:
        wf_vars["inputs.{}".format(input)] = wf_def['inputs'][input]['default']
    
    for parameter in wf_args:
        key = "inputs.{}".format(parameter)
        if key in wf_vars:
            wf_vars[key] = wf_args[parameter]
        else:
            sys.exit("Workflow parameter does not exist: {}".format(parameter))

    return wf_vars


def process_wf_vars (template, wf_vars, base_key):
    base_key = base_key if (base_key =='') else "{}.".format(base_key)
    out_str = template
    result = re.findall(r"<(\S+?)>", template)
    for var in result:
        out_str = out_str.replace("<{}>".format(var), str(wf_vars[base_key + var]))
    return out_str


def set_task_inputs (wf_vars, task_def, step_inputs, base_key):
    for parameter in task_def['inputs']:
        default = task_def['inputs'][parameter]['default'] if ('default' in task_def['inputs'][parameter]) else ''
        wf_vars["{}.inputs.{}".format(base_key, parameter)] = default

    for parameter in step_inputs:
        key = "{}.inputs.{}".format(base_key, parameter)
        wf_vars[key] = process_wf_vars(step_inputs[parameter], wf_vars, '')

    return wf_vars


def prepare_task_cmd (cmd_template, wf_vars, base_key):
    processed_cmd = cmd_template
    for i in range(len(cmd_template)):
        processed_cmd[i] = process_wf_vars(cmd_template[i], wf_vars, base_key)

    return processed_cmd


def set_task_outputs(wf_vars, task_def, base_key):
    for parameter in task_def['outputs']:
        wf_vars["{}.outputs.{}".format(base_key, parameter)] = process_wf_vars(task_def['outputs'][parameter]['value'], wf_vars, base_key)

    return wf_vars


def run_task_command(cmd):
    result = object()
    try:
        result = subprocess.run(
            cmd,
            text=True,
            check=True,
            capture_output=True
        )
    except subprocess.CalledProcessError as e:
        result = e

    return result


def check_cmd_result(wf_def, step, result):
    if result.returncode == 0:
        next_step = wf_def['pipeline'][step]['check_output']['returncode_0']
    else:
        next_step = wf_def['pipeline'][step]['check_output']['returncode_1']
    
    return next_step


class log_stdout():
    def __init__(self, logfile):
        self.stdout = sys.stdout
        self.log = open(logfile, 'w')

    def write(self, text):
        self.stdout.write(text)
        self.log.write(text)

    def close(self):
        self.stdout.close()
        self.log.close()

    def flush(self):
        pass


# Read wf definition
with open(args.wf_definition) as f:
    wf_def = json.load(f)

# Read wf tasks
with open(args.wf_tasks) as f:
    wf_tasks = json.load(f)

# Read wf arguments
with open(args.wf_arguments) as f:
    wf_args = json.load(f)

# Set wf input vars from wf definition and arguments
wf_vars = set_wf_inputs(wf_def, wf_args)
wf_vars['inputs.final_file_location'] = wf_vars['inputs.final_file_location'] if (wf_vars['inputs.final_file_location'][-1] == "/") else (wf_vars['inputs.final_file_location'] + "/")

# Open log file
os.system("mkdir -p {}".format(wf_vars['inputs.final_file_location']))
wf_log = "{}{}.log".format(wf_vars['inputs.final_file_location'], wf_def['name'])
sys.stdout = log_stdout(wf_log)
print("Initializing workflow {}\n".format(wf_def['name']))

# Run wf
next_step = {
    'step': wf_def['entry_point'],
    'inputs': wf_def['entry_point_inputs'],
}
while next_step['step'] != 'exit':
    print("Running {}".format(next_step['step']))
    # Create directory for step
    step_dir = "{}{}".format(wf_vars['inputs.final_file_location'], next_step['step'])
    os.system("mkdir -p {}".format(step_dir))
    # Open log for step
    step_log = "{}/{}.log".format(step_dir, next_step['step'])
    f = open(step_log, 'w')
    # Set task inputs
    base_key = "steps.{}".format(next_step['step'])
    task = wf_def['pipeline'][next_step['step']]['task']
    wf_vars = set_task_inputs(wf_vars, wf_tasks[task], next_step['inputs'], base_key)
    # Prepare task command
    cmd = prepare_task_cmd(wf_tasks[task]['cmd'], wf_vars, base_key)
    f.write("\n".join(str(item) for item in cmd) + "\n")
    # Set task outputs
    wf_vars = set_task_outputs(wf_vars, wf_tasks[task], base_key)
    # Run task command
    result = run_task_command(cmd)
    # Check result
    next_step = check_cmd_result(wf_def, next_step['step'], result)
    if next_step['step'] == 'error':
        f.write(result.stderr)
        print(result.stderr)
        sys.exit(result.stderr)
    elif next_step['step'] == 'exit':
        print("Workflow {} complete".format(wf_def['name']))
    else:
        f.write(result.stdout + "\n")
        print("Task {} complete\n".format(task))

    f.close()
