#!/bin/bash
args_array=("$@")

# Check for required parameters
if [ -z "$task" ]; then
    echo "task not provided, exiting!"
    exit
fi
if [ -z "$run_metadata_output_dir" ]; then
    echo "run_metadata_output_dir not provided, exiting!"
    exit
fi
if [ -z "$aws_access_key_id" ]; then
    echo "aws_access_key_id not provided, exiting!"
    exit
fi
if [ -z "$aws_secret_access_key" ]; then
    echo "aws_secret_access_key not provided, exiting!"
    exit
fi
if [ -z "$aws_region_name" ]; then
    echo "aws_region_name not provided, exiting!"
    exit
fi
# Assign default values if parameters not provided
if [ -z "$role_arn" ]; then
    role_arn="arn:aws:iam::515876044319:role/service-role/OmicsWorkflow-20240601210363"
fi
if [ -z "$output_uri" ]; then
    output_uri="s3://rti-nida-iomics-oa-healthomics-output/"
fi
if [ -z "$storage_capacity" ]; then
    storage_capacity=1000
fi

if [[ "$task" == "launch_step_1" ]]; then

    # Check parameters and set to default if not provided where applicable
    if [ -z "$parameters" ]; then
        echo "parameters not provided, exiting!"
        exit 
    fi
    if [ -z "$name" ]; then
        echo "name not provided, exiting!"
        exit 
    fi
    if [ -z "$workflow_id" ]; then
        workflow_id="3565858"
    fi

    # Launch Step 1
    python3 /opt/start_run.py \
        --run_metadata_output_dir $run_metadata_output_dir \
        --aws_access_key_id $aws_access_key_id \
        --aws_secret_access_key $aws_secret_access_key \
        --aws_region_name $aws_region_name \
        --workflowId $workflow_id \
        --parameters $parameters \
        --name $name \
        --roleArn $role_arn \
        --outputUri $output_uri \
        --storageCapacity $storage_capacity
fi

if [[ "$task" == "launch_step_2" ]]; then

    if [ -z "$step_1_run_metadata_json" ]; then
        echo "step_1_run_metadata_json not provided, exiting!"
        exit 
    fi
    if [ -z "$step_2_config_output_dir" ]; then
        echo "step_2_config_output_dir not provided, exiting!"
        exit 
    fi
    if [ -z "$minimum_ancestry_sample_count" ]; then
        minimum_ancestry_sample_count=50
    fi
    if [ -z "$workflow_id" ]; then
        workflow_id="4708363"
    fi
    
    # Create Step 2 config files
    python3 /opt/create_step_2_config.py \
        --aws_access_key_id $aws_access_key_id \
        --aws_secret_access_key $aws_secret_access_key \
        --aws_region_name $aws_region_name \
        --step_1_run_metadata_json $step_1_run_metadata_json \
        --output_dir $step_2_config_output_dir \
        --minimum_ancestry_sample_count $minimum_ancestry_sample_count
    
    # Launch Step 2
    step_2_config_output_dir=$(echo $step_2_config_output_dir | perl -ne 'chomp; if (substr($_, -1) eq "/") { print $_; } else { print $_."/"; }')
    for step_2_config in $(ls ${step_2_config_output_dir}*step_2_config*.json); do
        name=$(perl -ne 'if (/\"output_basename\"\: \"(.+?)\"/) { print $1; }' $step_2_config)
        python3 /opt/start_run.py \
            --run_metadata_output_dir $run_metadata_output_dir \
            --aws_access_key_id $aws_access_key_id \
            --aws_secret_access_key $aws_secret_access_key \
            --aws_region_name $aws_region_name \
            --workflowId $workflow_id \
            --parameters $step_2_config \
            --name $name \
            --roleArn $role_arn \
            --outputUri $output_uri \
            --storageCapacity $storage_capacity
        sleep 5s
    done

fi
