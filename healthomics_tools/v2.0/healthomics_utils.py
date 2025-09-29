import boto3
import sys

def get_run_metadata(aws_profile, run_id):
    """
    Retrieves details of a specific HealthOmics run by its ID.
    """
    try:
        session = boto3.Session(profile_name=aws_profile)
        omics_client = session.client('omics')
    except Exception as e:
        print(f"Error creating AWS session: {e}")
        sys.exit(1)

    try:
        response = omics_client.get_run(id=run_id)
        return response
    except omics_client.exceptions.ResourceNotFoundException:
        print(f"Run with ID {run_id} not found.")
        sys.exit(1)
    except Exception as e:
        print(f"Error retrieving run {run_id}: {e}")
        sys.exit(1)


def get_run_ids(aws_profile, run_statuses):
    """
    Retrieves a list of HealthOmics run IDs based on provided run IDs or statuses.
    """
    try:
        session = boto3.Session(profile_name=aws_profile)
        omics_client = session.client('omics')
    except Exception as e:
        print(f"Error creating AWS session: {e}")
        sys.exit(1)
        
    try:
        run_ids = []
        for status in run_statuses:
            paginator = omics_client.get_paginator('list_runs')
            pages = paginator.paginate(status=status)
            for page in pages:
                if 'items' in page:
                    for run in page['items']:
                        run_ids.append(run['id'])

        return run_ids
    except Exception as e:
        print(f"Error retrieving runs: {e}")
        sys.exit(1)


def cancel_healthomics_runs(aws_profile, run_ids):
    """
    Cancels all active AWS HealthOmics runs in the current AWS region.
    """
    try:
        session = boto3.Session(profile_name=aws_profile)
        omics_client = session.client('omics')
    except Exception as e:
        print(f"Error creating AWS session: {e}")
        sys.exit(1)

    cancelled_runs = []
    for run_id in run_ids:
        try:
            omics_client.cancel_run(id=run_id)
            cancelled_runs.append(run_id)
            print(f"Successfully cancelled run: {run_id}")
        except omics_client.exceptions.AccessDeniedException:
            print(f"Access Denied: Could not cancel run {run_id}. Check IAM permissions.")
        except Exception as e:
            print(f"Error cancelling run {run_id}: {e}")

    return cancelled_runs


def delete_runs(aws_profile, run_ids):
    """
    Deletes data associated with specified HealthOmics runs.
    """
    try:
        session = boto3.Session(profile_name=aws_profile)
        omics_client = session.client('omics')
    except Exception as e:
        print(f"Error creating AWS session: {e}")
        sys.exit(1)

    for run_id in run_ids:
        try:
            omics_client.delete_run(id=run_id)
            print(f"Successfully deleted data for run: {run_id}")
        except omics_client.exceptions.AccessDeniedException:
            print(f"Access Denied: Could not delete data for run {run_id}. Check IAM permissions.")
        except Exception as e:
            print(f"Error deleting data for run {run_id}: {e}")
