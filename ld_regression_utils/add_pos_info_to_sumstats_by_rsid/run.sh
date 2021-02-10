#!/usr/bin/env bash

source activate add_pos_info

python /opt/ld_regression/add_pos_info_to_sumstats_by_rsid.py "$@"