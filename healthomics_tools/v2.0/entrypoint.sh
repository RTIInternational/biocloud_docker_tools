#!/bin/bash
args_array=("$@")

# Check for required parameters
if [ -z "$task" ]; then
    echo "--task not provided, exiting!"
    exit
fi
if [ -z "$aws_profile" ]; then
    echo "--aws_profile not provided, exiting!"
    exit
fi
if [ -z "$AWS_SHARED_CREDENTIALS_FILE" ]; then
    echo "--AWS_SHARED_CREDENTIALS_FILE not provided, exiting!"
    exit
fi

# Builds a "--flag value" pair in py_args for each listed env var that is non-empty;
# unset/empty vars are simply omitted so each script's own argparse defaults/requirements apply.
build_args() {
    py_args=()
    for var_name in "$@"; do
        if [ -n "${!var_name}" ]; then
            py_args+=("--${var_name}" "${!var_name}")
        fi
    done
}

if [[ "$task" == "create_wf" ]]; then

    # Add repo to list of safe directories
    git config --global --add safe.directory "$repo_dir"

    # Create workflow
    build_args aws_profile repo_dir main name description readme engine storage_capacity
    python3 /opt/create_wf.py "${py_args[@]}"

fi

if [[ "$task" == "create_wf_version" ]]; then

    # Add repo to list of safe directories
    git config --global --add safe.directory "$repo_dir"

    # Create workflow version
    build_args aws_profile repo_dir workflow_id main name description readme engine storage_capacity
    python3 /opt/create_wf_version.py "${py_args[@]}"

fi

if [[ "$task" == "start_run" ]]; then

    # Start run
    build_args charge_code aws_profile workflow_id workflow_version_name workflow_owner_id \
        run_group_id run_id role_arn name cache_id cache_behavior parameters output_uri \
        run_metadata_output_dir workflow_type priority storage_type storage_capacity \
        log_level retention_mode networking_mode scratch_storage_mode configuration_name
    python3 /opt/start_run.py "${py_args[@]}"

fi

if [[ "$task" == "cancel_runs" ]]; then

    if [ -z "$run_ids" ] && [ -z "$run_statuses" ]; then
        echo "Either --run_ids or --run_statuses must be provided to cancel runs, exiting!"
        exit 
    fi

    build_args aws_profile run_ids run_statuses
    if [ -n "$delete_run_data" ]; then
        delete_run_data_upper=$(echo "$delete_run_data" | tr '[:lower:]' '[:upper:]')
        if [[ "$delete_run_data_upper" == "TRUE" || "$delete_run_data_upper" == "T" ]]; then
            py_args+=("--delete_run_data")
        fi
    fi

    python3 /opt/cancel_runs.py "${py_args[@]}"

fi

if [[ "$task" == "delete_runs" ]]; then

    if [ -z "$run_ids" ] && [ -z "$run_statuses" ]; then
        echo "Either --run_ids or --run_statuses must be provided to cancel runs, exiting!"
        exit 
    fi

    build_args aws_profile run_ids run_statuses
    python3 /opt/delete_runs.py "${py_args[@]}"

fi

if [[ "$task" == "retrieve_run_results" ]]; then

    build_args aws_profile run_id target_dir
    python3 /opt/retrieve_run_results.py "${py_args[@]}"

fi
