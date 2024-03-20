#!/bin/bash
args_array=("$@")

if [ -z "$wf_arguments" ]; then
    echo "wf_arguments not provided, exiting!"
    exit 
else
    /opt/extract_gvcf_variants.pl \
        --wf_arguments $wf_arguments
fi
