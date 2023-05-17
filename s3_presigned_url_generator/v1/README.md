# S3 Presigned URL Generator

A command-line interface (CLI) tool to generate a bash script containing `curl` commands with presigned URLs for uploading files to Amazon S3. This tool enables external collaborators to upload their files to your S3 bucket securely using presigned URLs, eliminating the need for separate AWS accounts.

<br>


[Click here to go to the recommended docker usage example](#docker-anchor)

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

## Docker usage <a id="docker-anchor"></a>
**This is the recommended approach.**<br>
Here is a toy example of how you can use this script with just a docker command. 
```
docker run --rm -v $PWD/:/data/ rtibiocloud/s3_presigned_url_generator:v1_9eed02d \
    --infile /data/file_list.txt \
    --outfile /data/upload_script3.sh \
    --bucket rti-cool-project \
    --key-prefix scratch/some_rti_user/ \
    --expiration-days 7 \
    --aws-access-key AKIACCESSkeyEXAMPLE \
    --aws-secret-access-key qFyQSECRECTaccessKEYexample
```
* Note check the DockerHub rtibiocloud repository for the latest tag (i.e., replace `v1_9eed02d` if necessary), and don't forget to change the access keys in this toy example.

## Using the Upload Script

The generated `upload_script.sh` contains the necessary `curl` commands to upload files to the S3 location using presigned URLs. To use the script, follow these steps:

1. Ensure that you have the `upload_script.sh` and the files you want to upload in the same directory.
2. Open a terminal and navigate to the directory containing the `upload_script.sh` and the files.
3. Make the `upload_script.sh` file executable.`chmod +x upload_script.sh`
4. Execute the `upload_script.sh` script. `./upload_script.sh`

The script will start executing the `curl` commands, uploading each file to the specified S3 location using the presigned URLs.

_Note_: Depending on the number and size of the files, the upload process may take some time. Monitor the progress in the terminal.
Once the script finishes executing, all the files should be successfully uploaded to the S3 bucket and location specified in the script.


## Communicating with Collaborators

To ensure the successful upload of files by external collaborators, it is recommended to communicate with them and provide necessary instructions. Here's a template for an email you can send to collaborators:

<details>
  <summary>mock email</summary>

  <br>
  
  **Subject**: Uploading files to [Your Project Name] - Action Required

Dear Collaborator,

We are excited to work with you on [Your Project Name]. As part of our collaboration, we kindly request you to upload your files to our Amazon S3 bucket using the provided presigned URLs. This process ensures secure and efficient file transfers without requiring separate AWS accounts.

Here are the steps to upload your files:

1. Place the attached `upload_script.sh` file in the same directory as the files you want to upload.

2. Open a terminal and navigate to the directory containing the `upload_script.sh` and your files.
  
3. Execute the `upload_script.sh` script:
  ```shell
  bash upload_script.sh
  ```
  
This will start the upload process. The script will automatically upload your files to our S3 bucket using presigned URLs.
Once the upload is complete, please reply to this email with the MD5 checksum for each uploaded file. This will allow us to verify the integrity of the transferred files. 
  
If you encounter any issues or have any questions during the upload process, please feel free to reach out to us. We are here to assist you.

Thank you for your collaboration!

Best regards,<br>
[Your Name]<br>
[Your Organization]
</details>




<br><br>
___

## Support
For support or any questions, please reach out to Jesse Marks (jmarks@rti.org)
