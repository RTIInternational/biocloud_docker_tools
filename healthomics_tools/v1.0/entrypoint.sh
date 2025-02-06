#!/bin/bash
args_array=("$@")

# Check for required parameters
if [ -z "$task" ]; then
    echo "--task not provided, exiting!"
    exit
fi
if [ -z "$aws_access_key_id" ]; then
    echo "--aws_access_key_id not provided, exiting!"
    exit
fi
if [ -z "$aws_secret_access_key" ]; then
    echo "--aws_secret_access_key not provided, exiting!"
    exit
fi
if [ -z "$aws_region_name" ]; then
    echo "--aws_region_name not provided, exiting!"
    exit
fi

if [[ "$task" == "create_wf" ]]; then

    # Check parameters and set to default if not provided where applicable
    if [ -z "$repo_dir" ]; then
        echo "--repo_dir not provided, exiting!"
        exit 
    fi
    if [ -z "$main" ]; then
        echo "--main not provided, exiting!"
        exit 
    fi
    if [ -z "$name" ]; then
        echo "--name not provided, exiting!"
        exit 
    fi
    if [ -z "$description" ]; then
        echo "--description not provided, exiting!"
        exit 
    fi

    # Assign default values if parameters not provided
    if [ -z "$engine" ]; then
        engine="WDL"
    fi
    if [ -z "$storage_capacity" ]; then
        storage_capacity=2000
    fi

    # Add repo to list of safe directories
    git config --global --add safe.directory "$repo_dir"

    # Create workflow
    python3 /opt/create_wf.py \
        --aws_access_key_id "$aws_access_key_id" \
        --aws_secret_access_key "$aws_secret_access_key" \
        --aws_region_name "$aws_region_name" \
        --repo_dir "$repo_dir" \
        --main "$main" \
        --name "$name" \
        --description "$description" \
        --engine "$engine" \
        --storage_capacity $storage_capacity

fi

if [[ "$task" == "start_run" ]]; then

    # Check parameters and set to default if not provided where applicable
    if [ -z "$charge_code" ]; then
        echo "--charge_code not provided, exiting!"
        exit 
    fi
    if [ -z "$workflow_id" ]; then
        echo "--workflow_id not provided, exiting!"
        exit 
    fi
    if [ -z "$parameters" ]; then
        echo "--parameters not provided, exiting!"
        exit 
    fi
    if [ -z "$name" ]; then
        echo "--name not provided, exiting!"
        exit 
    fi
    if [ -z "$output_uri" ]; then
        echo "--output_uri not provided, exiting!"
        exit 
    fi
    if [ -z "$run_metadata_output_dir" ]; then
        echo "--run_metadata_output_dir not provided, exiting!"
        exit 
    fi

    # Assign default values if parameters not provided
    if [ -z "$workflow_type" ]; then
        workflow_type="PRIVATE"
    fi
    if [ -z "$priority" ]; then
        priority=100
    fi
    if [ -z "$storage_type" ]; then
        storage_type="STATIC"
    fi
    if [ -z "$storage_capacity" ]; then
        storage_capacity=2000
    fi
    if [ -z "$log_level" ]; then
        log_level="ALL"
    fi
    if [ -z "$retention_mode" ]; then
        retention_mode="RETAIN"
    fi
    
    # Start run
    python3 /opt/start_run.py \
        --charge_code "$charge_code" \
        --aws_access_key_id "$aws_access_key_id" \
        --aws_secret_access_key "$aws_secret_access_key" \
        --aws_region_name "$aws_region_name" \
        --workflow_id "$workflow_id" \
        --parameters "$parameters" \
        --name "$name" \
        --output_uri "$output_uri" \
        --run_metadata_output_dir "$run_metadata_output_dir" \
        --workflow_type "$workflow_type" \
        --priority $priority \
        --storage_type "$storage_type" \
        --storage_capacity $storage_capacity \
        --log_level "$log_level" \
        --retention_mode "$retention_mode"

fi


if [[ "$task" == "cancel_all_runs" ]]; then

    # Start run
    python3 /opt/cancel_all_runs.py \
        --aws_access_key_id "$aws_access_key_id" \
        --aws_secret_access_key "$aws_secret_access_key" \
        --aws_region_name "$aws_region_name"

fi


if [[ "$task" == "delete_runs" ]]; then

    param_run_status=''
    if [ -z "$run_status" ]; then
        param_run_status="--run_status $run_status"
    fi
    param_delete_run_data=''
    if [ -z "$run_status" ]; then
        param_run_status="--run_status $run_status"
    fi
    param_run_status=''
    if [ -z "$run_status" ]; then
        param_run_status="--run_status $run_status"
    fi

    # Start run
    python3 /opt/cancel_all_runs.py \
        --aws_access_key_id "$aws_access_key_id" \
        --aws_secret_access_key "$aws_secret_access_key" \
        --aws_region_name "$aws_region_name" \
        --param_run_status \
        --param_delete_run_data \
        --param_run_output_dir

fi
