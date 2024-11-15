import os
import paramiko
import argparse

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
    '--results_file',
    help='Results file to export',
    type = str
)
parser.add_argument(
    '--target_dir',
    help='Directory on SFTP server to which to upload results',
    type = str
)
args = parser.parse_args()

target_dir = args.target_dir if (args.target_dir[-1] == "/") else (args.target_dir + "/")

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

    # # Loop through each file in the local directory
    # for file_name in os.listdir('/home/merge-shared-folder/sharepoint-pdfs'):
    #     # Check if the file is a PDF
    #     if not file_name.endswith('.pdf'):
    #         continue

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
