import os
import paramiko
import argparse
import json
from stat import S_ISDIR, S_ISREG
import re

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

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(16384), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

source_dir = args.source_dir if (args.source_dir[-1] == "/") else (args.source_dir + "/")
target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")
os.system("mkdir -p {}".format(target_dir))

samples_to_download = []
previous_sample_downloads = []
if args.samples_to_download:
    with open(args.samples_to_download, 'r') as f:
        samples_to_download = json.load(f)
    download_limit = len(samples_to_download)
else:
    download_limit = args.download_limit
    #Load previously downloaded samples
    if (args.downloaded_samples):
        with open(args.downloaded_samples, 'r') as f:
            previous_sample_downloads = json.load(f)

# Set up logging
# logging.basicConfig(filename='/home/merge-shared-folder/logs/export_log/sftp.log', filemode='a', format='%(asctime)s - %(message)s', level=logging.ERROR)

# Create a Transport object
transport = paramiko.Transport((args.sftp_server, 22))
sftp = None

try:
    # Authenticate with the server
    transport.connect(username=args.username, password=args.password)

    # Create an SFTP client from the Transport
    sftp = paramiko.SFTPClient.from_transport(transport)

    # Download gvcfs and md5 files
    failed_checksums = []
    for sftp_dir_object in sftp.listdir_attr(args.source_dir):
        if (S_ISDIR(sftp_dir_object.st_mode)):
            for file in sftp.listdir_attr(args.source_dir + sftp_dir_object.filename):
                result = re.search(r'^(.*)\.hard-filtered.gvcf.gz$', file.filename)
                    if result:


        
        

    for sample, path in samples.items():
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

    # Use the put method to upload the file
    sftp.put(args.results_file, target_dir + os.path.basename(args.results_file))

    # # Move the file to the "/transferred" directory
    # os.rename(os.path.join('/home/merge-shared-folder/exported-PRSs', file_name), os.path.join('/home/merge-shared-folder/exported-PRSs/transferred', file_name))

except paramiko.SSHException as e:
    print(f"An error occurred during the file upload process: {e}")

finally:
    # Close the SFTP client and the Transport
    if sftp is not None:
        sftp.close()
    transport.close()
