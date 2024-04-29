import argparse
import boto3
import os
import json
import re

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--source_s3_bucket',
    help='S3 bucket containing files to transfer',
    type = str
)
parser.add_argument(
    '--s3_access_key',
    help='Access key for S3 bucket',
    type = str
)
parser.add_argument(
    '--s3_secret_access_key',
    help='Secret access key for S3 bucket',
    type = str
)
parser.add_argument(
    '--target_dir',
    help='Directory to copy files to',
    type = str
)
parser.add_argument(
    '--downloaded_samples',
    help='File containing list of previously samples - these samples are ignored in the source bucket',
    type = str
)
parser.add_argument(
    '--download_limit',
    help='Max number of samples to download',
    type = int,
    default = 1000
)
args = parser.parse_args()

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(16384), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")
os.system("mkdir -p {}".format(target_dir))

#Connecting to S3
session = boto3.Session(aws_access_key_id=args.s3_access_key, aws_secret_access_key=args.s3_secret_access_key)
s3 = session.resource('s3')
my_bucket = s3.Bucket(args.source_s3_bucket)

#Load previously downloaded samples
try:
    with open(args.downloaded_samples, 'r') as f:
        previous_sample_downloads = json.load(f)
except FileNotFoundError:
    previous_sample_downloads = []

#Make list of samples that have NOT been downloaded yet
source_manifest_file = ""
new_available_samples = {}
download_limit = args.download_limit
for s3_object in my_bucket.objects.all():
    if (".xlsx" in s3_object.key):
        source_manifest_file = s3_object.key
    if download_limit > 0:
        result = re.search('^(\S+/)(\d+).hard-filtered.gvcf.gz$', s3_object.key)
        if result:
            path = result.group(1)
            sample = result.group(2)
            if sample not in previous_sample_downloads and sample not in new_available_samples:
                new_available_samples[sample] = path
                download_limit = download_limit - 1

# Download gvcfs and md5 files
failed_checksums = []
for sample, path in new_available_samples.items():
    source_gvcf_file = "{}{}.hard-filtered.gvcf.gz".format(path, sample)
    target_gvcf_file = "{}{}.hard-filtered.gvcf.gz".format(target_dir, sample)
    print("Downloading {} to {}".format(source_gvcf_file, target_gvcf_file))
    try:
        my_bucket.download_file(source_gvcf_file, target_gvcf_file)
    except:
        print("Download of {} failed.".format(source_gvcf_file))
        continue
    source_md5_file = "{}{}.hard-filtered.gvcf.gz.md5".format(path, sample)
    target_md5_file = "{}{}.hard-filtered.gvcf.gz.md5".format(target_dir, sample)
    print("Downloading {} to {}".format(source_md5_file, target_md5_file))
    try:
        my_bucket.download_file(source_md5_file, target_md5_file)
    except:
        print("Download of {} failed. Skipping checksum check for {}.".format(source_md5_file, sample))
        previous_sample_downloads.append(sample)
    else:
        print("Checking checksum")
        with open(target_md5_file, 'a') as md5_file:
            md5_file.write("\t" + target_gvcf_file)
        result = os.system("md5sum -c " + target_md5_file)
        if result == 0:
            os.system("rm {}".format(target_md5_file))
            previous_sample_downloads.append(sample)
        else:
            os.system("rm {}*".format(target_gvcf_file))
            failed_checksums.append(sample)

# Download manifest
if source_manifest_file:
    target_manifest_file = target_dir + re.sub(r'.+/', '', source_manifest_file)
    print("Downloading {} to {}".format(source_manifest_file, target_manifest_file))
    my_bucket.download_file(source_manifest_file, target_manifest_file)
    with open("{}genedx_manifest_path.txt".format(target_dir), 'w') as f:
        f.write(target_manifest_file)
        
# Save the list of downloaded samples
print("Updating {}".format(args.downloaded_samples))
with open(args.downloaded_samples, 'w') as f:
    json.dump(previous_sample_downloads, f)

# Save the list of samples failing checksum
print("{} samples failed the checksum test.".format(len(failed_checksums)))
if len(failed_checksums) > 0:
    failed_checksums_json = "{}failed_checksums.json".format(target_dir)
    print("See {} for details".format(failed_checksums_json))
    with open(failed_checksums_json, 'w') as f:
        json.dump(failed_checksums, f)
