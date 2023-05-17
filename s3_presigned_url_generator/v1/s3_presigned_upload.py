import argparse
import boto3


def generate_presigned_urls(infile, outfile, bucket, key_prefix, expiration_days, access_key, secret_access_key):
    """
    Generate a bash script containing curl commands with presigned URLs for uploading files to S3.

    This script takes an input file containing a list of file names, and for each file, it generates a presigned URL
    using the provided AWS credentials. The presigned URL allows external collaborators to upload their files to the
    specified S3 bucket using curl commands. The generated curl commands are written to the output file as a bash script.

    Args:
        infile (str): Path to the input file containing the list of file names to generate presigned URLs for.
        outfile (str): Path to the output bash script file that will contain the generated curl commands.
        bucket (str): Name of the S3 bucket where the files will be uploaded.
        key_prefix (str): Prefix to be prepended to each file name as the S3 object key.
        expiration_days (int): Expiration duration in days for the generated presigned URLs.
        access_key (str): AWS access key to be used for authentication.
        secret_access_key (str): AWS secret access key to be used for authentication.

    Example:
        Let's assume you have an input file named 'file_list.txt' containing the following filenames:
        ```
        file1.txt
        file2.jpg
        file3.pdf
        ```

        You want to generate a bash script named 'upload_script.sh' that will contain the curl commands with presigned
        URLs for uploading these files to the S3 bucket 'my-bucket' with the key prefix 'uploads/' and a URL expiration
        of 7 days.

        You can execute the script as follows:
        ```
        python s3_presigned_upload.py \
            --infile file_list.txt \
            --outfile upload_script.sh \
            --bucket my-bucket \
            --key-prefix uploads/ \
            --expiration-days 7 \
            --aws-access-key YOUR_ACCESS_KEY \
            --aws-secret-access-key YOUR_SECRET_ACCESS_KEY
        ```

        The generated 'upload_script.sh' will contain the curl commands to upload the files using presigned URLs.
        You can share the 'upload_script.sh' with the external collaborators, and they can execute it in the same
        folder as their files to upload them to your S3 account.
    """

    session = boto3.Session(aws_access_key_id=access_key, aws_secret_access_key=secret_access_key)
    s3 = session.client("s3")

    with open(infile) as inF, open(outfile, "w") as outF:
        line = inF.readline()
        while line:
            seconds = expiration_days * 60 * 60 * 24

            key = "{}{}".format(key_prefix, line.strip())
            outurl = s3.generate_presigned_url(
                'put_object',
                Params={'Bucket': bucket, 'Key': key},
                ExpiresIn=seconds,
                HttpMethod='PUT'
            )

            outline1 = "##{}".format(line)  # comment line
            outline2 = "curl --request PUT --upload-file {} '{}'\n\n".format(line.strip(), outurl)

            outF.write(outline1)
            outF.write(outline2)
            line = inF.readline()

        outF.write("echo 'File(s) successfully uploaded to S3!'")
    print(f"Success!\nCreated the bash script '{outfile}' for uploading files to S3 via presigned URLs.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate presigned URLs for S3 objects")
    parser.add_argument("--infile", required=True, help="Input file path")
    parser.add_argument("--outfile", required=True, help="Output file path")
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key-prefix", "-k", dest="key_prefix", required=True, help="S3 key prefix")
    parser.add_argument("--expiration-days", "-e", dest="expiration_days", type=int, help="URL expiration in days")
    parser.add_argument("--aws-access-key","-a", dest="access_key",  required=True, type=str, help="AWS access key ID")
    parser.add_argument("--aws-secret-access-key", "-s", dest="secret_access_key", required=True, type=str, help="AWS secret access key")

    args = parser.parse_args()

    generate_presigned_urls(
        args.infile,
        args.outfile,
        args.bucket,
        args.key_prefix,
        args.expiration_days,
        args.access_key,
        args.secret_access_key
    )
