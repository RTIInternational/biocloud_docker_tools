import argparse
import boto3
import os

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--source_gvcf_dir',
    help='Directory from which to archive gvcfs',
    type = str,
    required = True
)
parser.add_argument(
    '--s3_access_key',
    help='Access key for S3 bucket',
    type = str,
    required = True
)
parser.add_argument(
    '--s3_secret_access_key',
    help='Secret access key for S3 bucket',
    type = str,
    required = True
)
parser.add_argument(
    '--target_s3_bucket',
    help='S3 bucket to which to archive gvcfs',
    type = str,
    required = False,
    default = "rti-early-check-seq"
)
parser.add_argument(
    '--target_s3_dir',
    help='S3 directory to which to archive gvcfs',
    type = str,
    required = False,
    default = "revvity"
)

args = parser.parse_args()

source_gvcf_dir = args.source_gvcf_dir if (args.source_gvcf_dir[-1] == "/") else (args.source_gvcf_dir + "/")
target_s3_dir = args.target_s3_dir if (args.target_s3_dir[-1] == "/") else (args.target_s3_dir + "/")

# Connect to S3
session = boto3.Session(aws_access_key_id=args.s3_access_key, aws_secret_access_key=args.s3_secret_access_key)
s3 = session.resource('s3')
target_bucket = s3.Bucket(args.target_s3_bucket)

# Make list of files to archive
files_to_archive = []
for filename in os.listdir(source_gvcf_dir):
    if filename.endswith(".gvcf.gz"):
        files_to_archive.append("{}{}".format(source_gvcf_dir, filename))

# Upload gvcfs to S3
for source_gvcf_file in files_to_archive:
    target_gvcf_file = "{}{}".format(target_s3_dir, os.path.basename(source_gvcf_file))
    print("Uploading {} to {}".format(source_gvcf_file, target_gvcf_file))
    try:
        target_bucket.upload_file(source_gvcf_file, target_gvcf_file, ExtraArgs={'StorageClass': 'GLACIER_IR'})
        print("Upload of {} to {}/{} complete.".format(source_gvcf_file, args.target_s3_bucket, target_gvcf_file))
    except:
        print("Upload of {} failed.".format(source_gvcf_file))
        continue
    # Delete the file after upload
    try:
        os.remove(source_gvcf_file)
        print("Deleted {} after upload.".format(source_gvcf_file))
    except:
        print("Failed to delete {} after upload.".format(source_gvcf_file))
        continue
        