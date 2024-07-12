import typer
import boto3
import pytz
import os
import sys
import datetime

from pathlib import Path
from botocore.exceptions import ClientError

app = typer.Typer()

"""Archives S3 objects recursively in a folder or deletes them if they have been archived for a specified time.

    Args:
        --bucket-name (str): The name of the S3 bucket that contains the object. (required)
        --prefix (str): The prefix of the object in the S3 bucket. (required)
        --aws-access-key-id (-a) AWS access key ID (required)
        --aws-secret-access-key (-s) AWS secret access key (required)
        --days-to-archive (default=180)
        --days-to-delete (default=180)
        --dry-run: Perform a trial run with no changes made (default: False)

    Returns:
        None

    Example usage:
    python script.py \
        --bucket-name my-bucket \
        --prefix my-folder \
        --days-to-archive 30 \
        --days-to-delete 365 \
        --aws-access-key-id AKIA12345 \
        --aws-secret-access-key abcde12345 \
        --dry-run

    This will move all objects in the "my-folder" folder of the "my-bucket" bucket
    that are older than 30 days from Standard storage to Intelligent-Tiering storage,
    and delete any objects in the same folder that are currently in Intelligent-Tiering
    and are older than 365 days.
    The default values for --days-to-archive and --days-to-delete are 180.
"""

@app.command()
def main(
    bucket_name: str = typer.Option(..., "--bucket-name", "-b", help="The name of the S3 bucket containing the objects.  **Currently hardcoded as `rti-cromwell-output` for safety reasons.** This feature is under development and cannot be used with other buckets at this time.")
    prefix: str = typer.Option(..., "--prefix", "-p", help="The name of the S3 folder (excluding the bucket name) to archive and delete recursively."),

    aws_access_key: str = typer.Option(..., "--aws-access-key", "-a", help="AWS access key ID"),
    aws_secret_access_key: str = typer.Option(..., "--aws-secret-access-key", "-s", help="AWS secret access key"),
    days_to_archive: int = typer.Option(180, "--days-to-archive", help="The number of days before moving the object to Intelligent-Tiering storage (default: 180)."),
    days_to_delete: int = typer.Option(180, "--days-to-delete", help="The number of days before deleting the object from Intelligent-Tiering storage (default: 180)."),
    dry_run: bool = typer.Option(False, "--dry-run", help="Perform a trial run with no changes made."),
):
    # hard coding rti-cromwell-output for safety
    # if a person knows what they are doing then they can edit the code themselves
    bucket_name = "rti-cromwell-output"


    # Create an S3 client
    client = boto3.client("s3",
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_access_key)
    s3 = boto3.resource("s3",
            aws_access_key_id=aws_access_key,
            aws_secret_access_key=aws_secret_access_key)

    utc = pytz.UTC

    archive_date = datetime.datetime.now() - datetime.timedelta(days=days_to_archive)
    delete_date = datetime.datetime.now() - datetime.timedelta(days=days_to_delete)

    def move_to_glacier(bucket_name: str, key: str):
        """Move the object from the given bucket and key to Intelligent-Tiering storage.

        Args:
            bucket_name (str): The name of the S3 bucket that contains the object.
            key (str): The key of the object in the S3 bucket.

        Returns:
            None
        """
        obj = s3.Object(bucket_name, key)
        size = obj.content_length
        print(f"size: {size}B")

        # 5GB limit
        if size > 5 * 1024 * 1024 * 1024:
            print("larger than 5GB, or 5,368,709,120 bytes")
            return

        if dry_run:
            print(f"[DRY-RUN] Would move object s3://{bucket_name}/{key} to Intelligent-Tiering.\n")
        else:
            obj.copy_from(CopySource={"Bucket": bucket_name, "Key": key}, StorageClass="INTELLIGENT_TIERING")
            print(f"Moved object s3://{bucket_name}/{key} to Intelligent-Tiering.\n")

    def delete_object(bucket_name: str, key: str):
        """Delete the object from the given bucket and key.

        Args:
            bucket_name (str): The name of the S3 bucket that contains the object.
            key (str): The key of the object in the S3 bucket.

        Returns:
            None
        """
        obj = s3.Object(bucket_name, key)
        size = obj.content_length
        print(f"size: {size}B")

        if dry_run:
            print(f"[DRY-RUN] Would delete object s3://{bucket_name}/{key}\n")
        else:
            response = client.delete_object(Bucket=bucket_name, Key=key)
            print(f"Deleted object s3://{bucket_name}/{key}\n")

    # generate the log file name with the current date
    now = datetime.datetime.now()
    log_file_name = f"rti_cromwell_output_cleanup_{now:%Y_%m_%d_%Hh_%Mm_%Ss}.txt"

    # open the log file and redirect standard output to it
    with open(log_file_name, "w") as log_file:
        sys.stdout = log_file

        try:
            # Check if the bucket exists
            s3.meta.client.head_bucket(Bucket=bucket_name)
        except Exception as e:
            if e.response["Error"]["Code"] == "404":
                print(f"\nError: Bucket '{bucket_name}' does not exist.\n\n")
            elif e.response["Error"]["Code"] == "NoSuchKey":
                print("Access key wrong.")
            else:
                print(f"\nError: {e}\n\n")

        # Check if the prefix exists
        objects = list(s3.Bucket(bucket_name).objects.filter(Prefix=prefix))
        if not objects:
            print(f"\nError: Prefix '{prefix}' does not exist in bucket '{bucket_name}'.\n\n")

        for object in objects:
            key = object.key
            if key[-1] == '/':
                continue
            storage_class = object.storage_class
            last_modified = object.last_modified
            print(f"\nobject: s3://{bucket_name}/{key}")
            print(f"current storage class: {storage_class}")

            if storage_class == "GLACIER" and last_modified.replace(tzinfo=pytz.utc) < utc.localize(delete_date):
                delete_object(bucket_name, key)
            elif storage_class == "INTELLIGENT_TIERING" and last_modified.replace(tzinfo=pytz.utc) < utc.localize(delete_date):
                delete_object(bucket_name, key)
            elif storage_class == "STANDARD" and last_modified.replace(tzinfo=pytz.utc) < utc.localize(archive_date):
                move_to_glacier(bucket_name, key)
            else:
                message = "No action necessary."
                print(message)

    # Reset standard output to console
    sys.stdout = sys.__stdout__

    if not dry_run:
        # upload logfile to s3
        s3.meta.client.upload_file(log_file_name, bucket_name, f"cromwell-cleanup-logs/{log_file_name}")

        # Delete the logfile from local
        os.remove(log_file_name)

    return

if __name__ == "__main__":
    app()
