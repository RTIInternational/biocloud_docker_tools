# S3 Presigned URL Generator

A command-line interface (CLI) tool to generate a bash script containing `curl` commands with presigned URLs for uploading files to Amazon S3. This tool enables external collaborators to upload their files to your S3 bucket securely using presigned URLs, eliminating the need for separate AWS accounts.

<br>

## Usage

```shell
python s3_presigned_upload.py \
  --infile <input_file> \
  --outfile <output_file> \
  --bucket <bucket_name> \
  --key-prefix <key_prefix> \
  --expiration-days <expiration_days> \
  --aws-access-key <access_key> \
  --aws-secret-access-key <secret_access_key>
```


Replace the following placeholders with the appropriate values:

- `<input_file>`: Path to the input file containing a list of file names to generate presigned URLs for.
- `<output_file>`: Path to the output bash script file that will contain the generated curl commands.
- `<bucket_name>`: Name of the S3 bucket where the files will be uploaded.
- `<key_prefix>`: Prefix to be prepended to each file name as the S3 object key.
- `<expiration_days>`: Expiration duration in days for the generated presigned URLs.
- `<access_key>`: AWS access key ID for authentication.
- `<secret_access_key>`: AWS secret access key for authentication.

* Note, you can typically find your access keys in your AWS CLI Configuration Files (`~/.aws/credentials`)

Example:

Let's assume you have an input file named `file_list.txt` containing the following filenames:

```
file1.txt
file2.jpg
file3.pdf
```

You want to generate a bash script named `upload_script.sh` that will contain the curl commands with presigned URLs for uploading these files to the S3 bucket `my-bucket` with the key prefix `uploads/` and a URL expiration of 7 days.

You can execute the script as follows:

```shell
python s3_presigned_upload.py \
    --infile file_list.txt \
    --outfile upload_script.sh \
    --bucket my-bucket \
    --key-prefix uploads/ \
    --expiration-days 7 \
    --aws-access-key YOUR_ACCESS_KEY \
    --aws-secret-access-key YOUR_SECRET_ACCESS_KEY
```

The generated `upload_script.sh` will contain the curl commands necessary to upload the files using presigned URLs. Share the `upload_script.sh` with the external collaborators, and they can execute it in the same folder as their files to upload them to your S3 account.


## Support
For support or any questions, please reach out to Jesse Marks (jmarks@rti.org)
