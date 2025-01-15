**_Note_**: Implementing Life Cycle Policies all but obsoletes this tool.
See our "Automatically Delete Data After 90 Days" policy we currenlty have in place for the `rti-cromwell-output` bucket.

<br>

# Archive and Delete Files from S3
Archives S3 objects recursively in a folder or deletes them if they have been archived for a specified time.

**Note:** The bucket name `rti-cromwell-output` is hardcoded into the code. So even if you specify a different bucket, `rti-cromwell-output` will still be used. This was done to prevent accidental deletion of data from other buckets.

## v1.1.0
This version leverages Typer to create a more modern CLI.
It is not as well tested as v1.0.0 though.
Still in beta.

<br><br>

## Usage

```bash
$ docker run -it rtibiocloud/archive_and_delete_from_s3:<latest-tag> \
    --bucket-name <bucket-name> \
    --prefix <folder-within-bucket> \
    --days-to-archive <archive-file-after-M-days> \
    --days-to-delete <delete-file-after-N-days> \
    --aws-access-key-id <access-key> \
    --aws-secret-access-key <secret-access-key>
```

example:
```
# get aws keys from hidden folder. input them as docker parameter
$ aws_access_key_id=$(perl -ane 'BEGIN {$take = 0;} if ($F[0] =~ /rti-code/) { $take = 1; } if ($take && $F[0] =~ /aws_access_key_id/) { print $F[2]; $take = 0; }' ~/.aws/credentials)
$ aws_secret_access_key_id=$(perl -ane 'BEGIN {$take = 0;} if ($F[0] =~ /rti-code/) { $take = 1; } if ($take && $F[0] =~ /aws_secret_access_key/) { print $F[2]; $take = 0; }' ~/.aws/credentials)

$ docker run -it rtibiocloud/archive_and_delete_from_s3:v1_9940a86  \
    --bucket-name rti-cromwell-output \
    --prefix cromwell-execution/metal_gwas_meta_analysis_wf/07c84f1f-d272-4808-94cc-c39332c65d87/ \
    --days-to-archive 30 \
    --days-to-delete 180 \
    --aws-access-key $aws_access_key_id \
    --aws-secret-access-key $aws_secret_access_key_id
```

This will move all objects in the `cromwell-execution/metal_gwas_meta_analysis_wf/07c84f1f-d272-4808-94cc-c39332c65d87/` folder of the `rti-cromwell-output` bucket that are older than 30 days from Standard Storage to Intelligent-Tiering Storage, and delete any objects in the same folder that are currently in Intelligent-Tiering and are older than 180 days.

The default values for `--days_to_archive` and `--days_to_delete` are 180.


<br><br>


## Contact
If you have any questions or suggestions, please feel free to contact Jesse Marks at jmarks@rti.org.
