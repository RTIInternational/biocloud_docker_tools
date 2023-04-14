import argparse
import boto3
import datetime
import pytz
import botocore
from botocore.exceptions import ClientError

"""Archives S3 objects recursively in a folder or deletes them if they have been archived for a specified time.

    Args:
        --bucket_name (str): The name of the S3 bucket that contains the object. (required)
        --prefix (str): The prefix of the object in the S3 bucket. (required)
        --aws-access-key-id (-a) AWS access key ID (required)
        --aws-secret-access-key (-s) AWS secret access key (required)
        --days-to-archive (default=180)
        --days-to-delete (default=180)

    Returns:
        None

    Example usage:
    python glacierize.py \
        --bucket-name my-bucket \
        --prefix my-folder \
        --days_to_archive 30 \
        --days_to_delete 365 \
        --aws-access-key-id AKIA12345 \
        --aws-secret-access-key abcde12345

    This will move all objects in the "my-folder" folder of the "my-bucket" bucket
    that are older than 30 days from Standard storage to Intelligent-Tiering storage,
    and delete any objects in the same folder that are currently in Intelligent-Tiering
    and are older than 365 days.
    The default values for --days_to_archive and --days_to_delete are 180.
"""


# Define the command-line arguments
parser = argparse.ArgumentParser(description="Moves S3 objects from Standard to Intelligent-Tiering storage or to Glacier storage.")
parser.add_argument("--bucket-name", "-b", dest="bucket_name", required=True, type=str, help="The name of the S3 bucket that contains the objects.")
parser.add_argument("--prefix", "-p", dest="prefix", type=str, required=True, help="The name of the S3 folder (exluding the bucket name) to archive and delete recursively.")
parser.add_argument("--aws-access-key","-a", dest="aws_access_key",  required=True, type=str, help="AWS access key ID")
parser.add_argument("--aws-secret-access-key", "-s", dest="aws_secret_access_key", required=True, type=str, help="AWS secret access key")

parser.add_argument("--days-to-archive", dest="days_to_archive", type=int, default=180, help="The number of days before moving the object to Intelligent-Tiering storage (default: 180).")
parser.add_argument("--days-to-delete", dest="days_to_delete", type=int, default=180, help="The number of days before deleting the object from Intelligent-Tiering storage (default: 180).")

# Parse the command-line arguments
args = parser.parse_args()
aws_access_key = args.aws_access_key
aws_secret_access_key = args.aws_secret_access_key
#bucket_name = args.bucket_name
bucket_name = "rti-cromwell-output"
days_to_archive = args.days_to_archive
days_to_delete = args.days_to_delete
prefix = args.prefix

# Create an S3 client
client = boto3.client("s3",
        aws_access_key_id = args.aws_access_key,
        aws_secret_access_key = args.aws_secret_access_key)
s3 = boto3.resource("s3",
        aws_access_key_id = args.aws_access_key,
        aws_secret_access_key = args.aws_secret_access_key)

utc=pytz.UTC

archive_date = datetime.datetime.now() - datetime.timedelta(days=days_to_archive)
delete_date = datetime.datetime.now() - datetime.timedelta(days=days_to_delete)


def move_to_glacier(bucket_name, key):
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
    obj.copy_from(CopySource={"Bucket": bucket_name, "Key": key}, StorageClass="INTELLIGENT_TIERING")

    print(f"Moved object s3://{bucket_name}/{key} to Intelligent-Tiering.\n")

def delete_object(bucket_name, key):
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

    response = client.delete_object(Bucket=bucket_name, Key=key)
    print(f"Deleted object s3://{bucket_name}/{key}\n")


def main():
    try:
        # Check if the bucket exists
        s3.meta.client.head_bucket(Bucket=bucket_name)
    except Exception as e:
        if e.response["Error"]["Code"] == "404":
            print(f"\nError: Bucket '{bucket_name}' does not exist.\n\n")
        elif e.response["Error"]["Code"] == "NoSuchKey":
            logger.info("Access key wrong.")

        else:
            print(f"\nError: {e}\n\n")

    # Check if the prefix exists
    objects = list(s3.Bucket(bucket_name).objects.filter(Prefix=prefix))
    if not objects:
        print(f"\nError: Prefix '{prefix}' does not exist in bucket '{bucket_name}'.\n\n")

    for object in objects:
        key = object.key
        if key[-1] == '/':
            #print("Skipping folder object.\n")
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
            print("No action necessary.")

if __name__ == "__main__":
    main()

