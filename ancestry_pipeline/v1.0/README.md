<details>
<summary>Usage</summary>

``` shell
docker run -ti -v /rti-01/ngaddis:/rti-01/ngaddis -e wf_arguments=/rti-01/ngaddis/data/temp/t1d_test3/ancestry_pipeline_test.json --rm biocloud_docker_tools/ancestry_pipeline:v1.0
```
</details>


<details>
<summary>Build instructions</summary>

``` shell
base_dir=/rti-01/ngaddis/git/biocloud_docker_tools/ancestry_pipeline/v1.0

# Create Dockerfile from template
perl -pe '
    use warnings;
    BEGIN {
        %s3Files = ();
        open(S3_FILES, "'$base_dir'/s3_files.tsv");
        while(<S3_FILES>) {
            chomp;
            @fields = split;
            $s3Files{$fields[0]} = `aws s3 presign $fields[1] --expires-in 360`;
            $s3Files{$fields[0]} =~ s/\n//;
        }
        close S3_FILES;
    }
    foreach $key (keys(%s3Files)) {
        s/$key/$s3Files{$key}/;
    }
' $base_dir/Dockerfile_template > $base_dir/Dockerfile

# Local build
cd $base_dir
docker build . -t biocloud_docker_tools/ancestry_pipeline:v1.0

```
</details>
