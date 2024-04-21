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

python3 /opt/run_pipeline.py \
    --wf_definition /opt/$wf_definition.json \
    --wf_tasks /opt/t1dgrs2_tasks.json \
    --wf_arguments $wf_arguments
