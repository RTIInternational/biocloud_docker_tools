import os
import paramiko
import argparse
import json
from stat import S_ISDIR, S_ISREG
import re
import pandas as pd

# Get arguments
parser = argparse.ArgumentParser()
parser.add_argument(
    '--sftp_server',
    help='SFTP server to which to export results',
    type = str
)
parser.add_argument(
    '--username',
    help='Username for SFTP server',
    type = str
)
parser.add_argument(
    '--password',
    help='Password for SFTP server',
    type = str
)
parser.add_argument(
    '--source_dir',
    help='Source directory on the SFTP server',
    type = str
)
parser.add_argument(
    '--target_dir',
    help='Directory on SFTP server to which to upload results',
    type = str
)
parser.add_argument(
    '--manifest_dir',
    help='Directory containing RTI manifests',
    type = str
)
parser.add_argument(
    '--downloaded_samples',
    help='File containing list of previously samples - these samples are ignored in the source bucket',
    type = str,
    required = True
)
parser.add_argument(
    '--download_limit',
    help='Max number of samples to download',
    type = int,
    default = 1000,
    required = False
)
parser.add_argument(
    '--samples_to_download',
    help='(Optional) List of files to download',
    type = str,
    required = False
)
args = parser.parse_args()

def initialize_dir (dir, create_dir = True):
    if dir:
        dir = dir if (dir[-1] == "/") else (dir + "/")
        if create_dir:
            os.system("mkdir -p {}".format(dir))
    return dir

source_dir = initialize_dir(args.source_dir, False)
target_dir = initialize_dir(args.target_dir)
manifest_dir = initialize_dir(args.manifest_dir)

# Get a list of consenting samples
consented_samples = []
for file in os.listdir(manifest_dir):
    if file[len(file) - 3:] == 'csv':
        manifest = pd.read_csv("{}{}".format(manifest_dir, file))
        manifest = manifest[manifest["ApprovalID"].str.contains(u'T1D')]
        consented_samples = consented_samples + manifest["Well #"].values.astype(str).tolist()

# Read in samples_to_download or previous_sample_downloads
samples_to_download = []
previous_sample_downloads = []
if args.samples_to_download:
    with open(args.samples_to_download, 'r') as f:
        samples_to_download = json.load(f)
    download_limit = len(samples_to_download)
else:
    download_limit = args.download_limit
    # Load previously downloaded samples
    if (args.downloaded_samples):
        with open(args.downloaded_samples, 'r') as f:
            previous_sample_downloads = json.load(f)

# Open sftp connection
try:
    transport = paramiko.Transport((args.sftp_server, 22))
    sftp = None
    transport.connect(username=args.username, password=args.password)
    sftp = paramiko.SFTPClient.from_transport(transport)
except paramiko.SSHException as e:
    print(f"An error occurred connecting to the SFTP server: {e}")

# Make list of samples to download
try:
    files_to_download = {}
    samples = []
    for sftp_dir_object in sftp.listdir_attr(args.source_dir):
        if download_limit > 0 and S_ISDIR(sftp_dir_object.st_mode):
            for file in sftp.listdir(args.source_dir + sftp_dir_object.filename):
                result = re.search(r'^\S+\-(\d+)_\d+-WGS.+\.hard-filtered.gvcf.gz$', file)
                if result:
                    rti_accession = result.group(1)
                    if rti_accession in consented_samples and download_limit > 0:
                        condition1 = len(samples_to_download) > 0 and rti_accession in samples_to_download
                        condition2 = len(samples_to_download) == 0 and  rti_accession not in previous_sample_downloads
                        if condition1 or condition2:
                            files_to_download[rti_accession] = {
                                'source_gvcf_file': "{}{}/{}".format(args.source_dir, sftp_dir_object.filename, file),
                                'target_gvcf_file': "{}{}".format(target_dir, file),
                                'source_md5_file': "{}{}/{}.md5sum".format(args.source_dir, sftp_dir_object.filename, file),
                                'target_md5_file': "{}{}.md5sum".format(target_dir, file)
                            }
                            samples.append(rti_accession)
                            download_limit = download_limit - 1
except:
    print(f"An error occurred retrieving list of files to download: {e}")

# Download gvcfs and md5 files
successful_downloads = []
failed_downloads = []
failed_checksums = []
for sample in files_to_download:
    try:
        print("Downloading {} to {}".format(files_to_download[sample]['source_gvcf_file'], files_to_download[sample]['target_gvcf_file']))
        sftp.get(files_to_download[sample]['source_gvcf_file'], files_to_download[sample]['target_gvcf_file'])
    except:
        print("Download of {} failed.".format(sample))
        failed_downloads.append(sample)
        continue
    try:
        print("Downloading {} to {}".format(files_to_download[sample]['source_md5_file'], files_to_download[sample]['target_md5_file']))
        sftp.get(files_to_download[sample]['source_md5_file'], files_to_download[sample]['target_md5_file'])
    except:
        print("Download of {} failed. Skipping checksum check for {}.".format(source_md5_file, sample))
        failed_downloads.append(sample)
        continue
    else:
        print("Checking integrity of {}".format(files_to_download[sample]['target_gvcf_file']))
        with open(files_to_download[sample]['target_md5_file'], 'r') as md5_file:
            md5 = md5_file.read().rstrip()
        with open(files_to_download[sample]['target_md5_file'], 'w') as md5_file:
            md5_file.write("{}\t{}".format(md5, files_to_download[sample]['target_gvcf_file']))
        result = os.system("md5sum -c " + files_to_download[sample]['target_md5_file'])
        if result == 0:
            os.system("rm {}".format(files_to_download[sample]['target_md5_file']))
            successful_downloads.append(sample)
            previous_sample_downloads.append(sample)
        else:
            os.system("rm {}".format(files_to_download[sample]['target_gvcf_file']))
            os.system("rm {}".format(files_to_download[sample]['target_md5_file']))
            failed_checksums.append(sample)

# Close sftp connection
if sftp is not None:
    sftp.close()
transport.close()

# Save the list of downloaded samples
print("Downloaded {} samples".format(len(samples)))
print("Updating {}".format(args.downloaded_samples))
with open(args.downloaded_samples, 'w') as f:
    json.dump(sorted(set(previous_sample_downloads)), f)

# Save the list of samples successfully downloaded
print("{} samples downloaded.".format(len(successful_downloads)))
successful_downloads_json = "{}successful_downloads.json".format(target_dir)
print("See {} for details".format(successful_downloads_json))
with open(successful_downloads_json, 'w') as f:
    json.dump(successful_downloads, f)

# Save the list of samples failing download
print("{} samples failed to download.".format(len(failed_downloads)))
failed_downloads_json = "{}failed_downloads.json".format(target_dir)
print("See {} for details".format(failed_downloads_json))
with open(failed_downloads_json, 'w') as f:
    json.dump(failed_downloads, f)

# Save the list of samples failing checksum
print("{} samples failed the checksum test.".format(len(failed_downloads)))
failed_checksums_json = "{}failed_checksums.json".format(target_dir)
print("See {} for details".format(failed_checksums_json))
with open(failed_checksums_json, 'w') as f:
    json.dump(failed_checksums, f)
