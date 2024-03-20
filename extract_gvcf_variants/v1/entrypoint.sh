#!/bin/bash
args_array=("$@")

if [ -z "$wf_arguments" ]; then
    echo "wf_arguments not provided, exiting!"
    exit 
else
    /opt/extract_gvcf_variants.pl \
        --args $wf_arguments
fi
