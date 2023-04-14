# Archive and Delete Files from S3
Archives S3 objects recursively in a folder or deletes them if they have been archived for a specified time.

*Note*: `rti-cromwell-output` is hard coded into the code. So even if you provide a different bucket, `rti-cromwell-output` will be used.

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
$ docker run -it rtibiocloud/archive_and_delete_from_s3:v1_d530ae5 \
    --bucket-name rti-cromwell-output \
    --prefix cromwell-execution/metal_gwas_meta_analysis_wf/07c84f1f-d272-4808-94cc-c39332c65d87/ \
    --days-to-archive 30 \
    --days-to-delete 180 \
    --aws-access-key-id AKIA12345 \
    --aws-secret-access-key abcde12345
```
This will move all objects in the "cromwell-execution/metal_gwas_meta_analysis_wf/07c84f1f-d272-4808-94cc-c39332c65d87/"
folder of the "rti-cromwell-output" bucket that are older than 30 days from Standard storage to Intelligent-Tiering storage,
and delete any objects in the same folder that are currently in Intelligent-Tiering and are older than 180 days.
The default values for --days_to_archive and --days_to_delete are 180.


<br><br>



## Contact
If you have any questions or suggestions, please feel free to contact Jesse Marks at jmarks@rti.org.
