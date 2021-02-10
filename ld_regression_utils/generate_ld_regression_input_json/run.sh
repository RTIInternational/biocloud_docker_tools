#!/usr/bin/env bash

source activate generate_input

python /opt/ld_regression/generate_ld_regression_input_json.py "$@"