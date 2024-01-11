#!/bin/bash
args_array=("$@")

if [ -z "$wf_arguments" ]; then
    echo "wf_arguments not provided, exiting!"
    exit 
else
    python3 /opt/run_pipeline.py \
        --wf_definition /opt/ancestry_pipeline.json \
        --wf_tasks /opt/ancestry_tasks.json \
        --wf_arguments $wf_arguments
fi
