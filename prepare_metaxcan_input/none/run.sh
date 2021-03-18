#!/usr/bin/env bash

# Fix ownership of output files
finish() {
    # Fix ownership of output files
    user_id=$(stat -c '%u:%g' /data)
    chown -R ${user_id} /data
}
trap finish EXIT

/bin/bash /opt/code_docker_lib/prepare_metaxcan_input.sh "$@"

