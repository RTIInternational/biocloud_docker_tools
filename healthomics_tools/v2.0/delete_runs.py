import argparse
from healthomics_utils import get_run_ids, delete_runs

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--aws_profile',
    help='AWS profile to use for credentials',
    type = str,
    required = True
)
parser.add_argument(
    '--run_ids',
    help='Run IDs of runs to cancel (separated by commas)',
    type = str,
    required = False
)
parser.add_argument(
    '--run_statuses',
    help='Run statuses of runs to cancel (separated by commas)',
    type = str,
    required = False
)
args = parser.parse_args()

# Get run IDs to cancel
run_ids = []
if args.run_ids:
    run_ids = args.run_ids.split(',')

if args.run_statuses:
    run_ids = run_ids + get_run_ids(args.aws_profile, run_statuses=args.run_statuses.split(','))
    
if not run_ids:
    print("No runs found to cancel based on the provided criteria.")
else:
    # Delete runs
    print(f"Attempting to delete data for {len(run_ids)} runs.")
    delete_runs(args.aws_profile, run_ids=run_ids)
    print(f"Successfully deleted data for runs: {', '.join(run_ids)}")
    