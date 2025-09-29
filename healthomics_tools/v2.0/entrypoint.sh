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

if [[ "$task" == "cancel_runs" ]]; then

    if [ -z "$run_ids" ] && [ -z "$run_statuses" ]; then
        echo "Either --run_ids or --run_statuses must be provided to cancel runs, exiting!"
        exit 
    fi

    param_run_ids=''
    if [ -n "$run_ids" ]; then
        param_run_ids="--run_ids $run_ids"
    fi
    param_run_statuses=''
    if [ -n "$run_statuses" ]; then
        param_run_statuses="--run_statuses $run_statuses"
    fi
    if [ -n "$delete_run_data" ]; then
        param_delete_run_data=$(echo "$delete_run_data" | perl -ne 'chomp; $deleteRunData = uc($_); if ($deleteRunData eq "TRUE" || $deleteRunData eq "T") { print "--delete_run_data" } else { print "" }')
    fi

    python3 /opt/cancel_runs.py \
        --aws_profile "$aws_profile" \
        $param_run_ids \
        $param_run_statuses \
        $param_delete_run_data

fi

if [[ "$task" == "delete_runs" ]]; then

    if [ -z "$run_ids" ] && [ -z "$run_statuses" ]; then
        echo "Either --run_ids or --run_statuses must be provided to cancel runs, exiting!"
        exit 
    fi

    param_run_ids=''
    if [ -n "$run_ids" ]; then
        param_run_ids="--run_ids $run_ids"
    fi
    param_run_statuses=''
    if [ -n "$run_statuses" ]; then
        param_run_statuses="--run_statuses $run_statuses"
    fi

    python3 /opt/delete_runs.py \
        --aws_profile "$aws_profile" \
        $param_run_ids \
        $param_run_statuses

fi

if [[ "$task" == "retrieve_run_results" ]]; then

    # Check parameters and set to default if not provided where applicable
    if [ -z "$run_id" ]; then
        echo "--run_id not provided, exiting!"
        exit 
    fi
    if [ -z "$target_dir" ]; then
        echo "--target_dir not provided, exiting!"
        exit 
    fi

    # Retrieve run results
    python3 /opt/retrieve_run_results.py \
        --aws_profile "$aws_profile" \
        --run_id "$run_id" \
        --target_dir "$target_dir"

fi