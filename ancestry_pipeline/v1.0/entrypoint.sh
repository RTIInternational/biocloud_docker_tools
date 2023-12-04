#!/bin/bash
args_array=("$@")

if [ -z "$wf_arguments" ]; then
    echo "wf_arguments not provided, exiting!"
    exit 
else
    python3 /opt/run_pipeline.py \
        --wf_config /opt/ancestry_pipeline_config.json \
        --wf_arguments $wf_arguments
fi
