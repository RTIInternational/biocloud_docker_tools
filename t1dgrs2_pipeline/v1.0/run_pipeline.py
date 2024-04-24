import argparse
import json
import subprocess
import re
import sys
import os
import copy
import logging

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
    out_str = copy.deepcopy(template)
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


def prepare_task_cmd (cmd_template, wf_vars, base_key):
    processed_cmd = copy.deepcopy(cmd_template)
    for i in range(len(cmd_template)):
        processed_cmd[i] = process_wf_vars(cmd_template[i], wf_vars, base_key)

    return processed_cmd


def set_task_outputs(wf_vars, task_def, base_key):
    for parameter in task_def['outputs']:
        wf_vars["{}.outputs.{}".format(base_key, parameter)] = process_wf_vars(task_def['outputs'][parameter]['value'], wf_vars, base_key)


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


def setup_logger(name, log_file, level=logging.INFO):
    handler = logging.FileHandler(log_file)
    handler.setFormatter(logging.Formatter('%(asctime)s %(levelname)s %(message)s'))
    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.addHandler(handler)

    return logger


class logger_writer:
    def __init__(self, level):
        self.level = level

    def write(self, message):
        if message != '\n':
            self.level(message)

    def flush(self):
        self.level(sys.stderr)


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
wf_vars['inputs.working_dir'] = wf_vars['inputs.working_dir'] if (wf_vars['inputs.working_dir'][-1] == "/") else (wf_vars['inputs.working_dir'] + "/")

# Create working dir if it doesn't exist
os.system("mkdir -p {}".format(wf_vars['inputs.working_dir']))

# Open log for wf
wf_log = "{}{}.log".format(wf_vars['inputs.working_dir'], wf_def['name'])
wf_logger = setup_logger('wf_logger', wf_log)
wf_logger.info("Initializing workflow {}".format(wf_def['name']))

# Run wf
next_step = {
    'step': wf_def['entry_point'],
    'inputs': wf_def['entry_point_inputs'],
}
while next_step['step'] != 'exit':
    # Create directory for step
    step_dir = "{}{}".format(wf_vars['inputs.working_dir'], next_step['step'])
    os.system("mkdir -p {}".format(step_dir))
    # Set task inputs
    base_key = "steps.{}".format(next_step['step'])
    task = wf_def['pipeline'][next_step['step']]['task']
    set_task_inputs(wf_vars, wf_tasks[task], next_step['inputs'], base_key)
    # Open log file
    step_log = "{}/{}.log".format(step_dir, next_step['step'])
    step_logger = setup_logger('step_logger', step_log)
    sys.stdout = logger_writer(step_logger.info)
    sys.stderr = logger_writer(step_logger.error)
    step_logger.info("Running task {}".format(task))
    wf_logger.info("Running task {}".format(task))
    # Prepare task command
    cmd = prepare_task_cmd(wf_tasks[task]['cmd'], wf_vars, base_key)
    print("\n".join(str(item) for item in cmd) + "\n")
    # Set task outputs
    set_task_outputs(wf_vars, wf_tasks[task], base_key)
    # Run task command
    result = run_task_command(cmd)
    # Check result
    next_step = check_cmd_result(wf_def, next_step['step'], result)
    if next_step['step'] == 'error':
        step_logger.error(result.stderr)
        wf_logger.error(result.stderr)
        sys.exit(result.stderr)
    elif next_step['step'] == 'exit':
        step_logger.info(result.stdout)
        step_logger.info("Task {} complete".format(task))
        wf_logger.info("Workflow {} complete".format(wf_def['name']))
    else:
        step_logger.info(result.stdout)
        step_logger.info("Task {} complete".format(task))
    step_log.close()

wf_log.close()
