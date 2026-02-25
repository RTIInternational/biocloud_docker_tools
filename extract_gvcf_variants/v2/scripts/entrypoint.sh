#!/bin/bash
args_array=("$@")

if [ -z "$wf_definition" ]; then
    echo "wf_definition not provided, exiting!"
    exit 
fi
if [ -z "$wf_arguments" ]; then
    echo "wf_arguments not provided, exiting!"
    exit 
fi

python3 /pipeline/scripts/run_pipeline.py \
    --wf_definition /pipeline/config/$wf_definition.json \
    --wf_tasks /pipeline/config/tasks.json \
    --wf_arguments $wf_arguments
