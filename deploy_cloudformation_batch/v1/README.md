# New job queue for WDL workflows
## Create new `Launch Template Stack` and `Batch Stack`

We use AWS Batch to facilitate the execution of our WDL workflows. Each project/analysis requires that compute time is charged to the appropriate project.
Thus, for each analysis using WDL we have to create an appropriate job-queue, so that charge codes are prolifereted to the EC2 instances running the jobs.

This script simplifies the process of creating a new job-queue and compute environment within AWS Batch.
In particular, this Bash script creates a Launch Template and a Batch Compute Stack for a given project based on existing infrastructure as a template.

The script requires the following parameters:
* `projectNumber`: The project number (charge code).
* `projectShortName`: A short descriptive name of the project.

The user can optionally supply these additional parameters:
* `cpuMax`: The maximum number of vCPUs for each EC2 instance. 
* `stackName`: The name of the master stack to be used as a template.
* `profile`: The AWS profile to use.

<br>


## Usage

This docker image was created to be used interactively. Login, configure your AWS environment, then deploy the batch environment using the wiki guidance provided at
 https://github.com/RTIInternational/bioinformatics/wiki/Cromwell-Cloud-Deployment#aws-cli---create-new-batch-queue

<br><br>

**example**
```
# start interactive mode
docker run -it rtibiocloud/deploy_cloudformation_batch:v1_e7476c4 bash

# configure credentials by running "aws configure". Be sure to use json for output format.
aws configure
  #AWS Access Key ID [None]: <enter-your-secret-access-key>
  #AWS Secret Access Key [None]: <enter-your-secret-access-key>
  #Default region name [None]: us-east-1
  #Default output format [None]: json
  
# verify configuration by listing S3 buckets  
aws s3 ls
  #2021-08-10 21:02:09 agc-404545384114-us-east-1
  #2020-02-26 15:05:01 rti-alcohol
  #2020-11-20 17:36:18 rti-cannabis
  #2017-10-13 13:23:33 rti-common
  #...
  
# create environment
bash /opt/deploy-cloudformation-batch.sh \
  --projectNumber 0217653.001.001 \
  --projectShortName "hiv-gnetii"
  
Launch Template ARN: {
    "StackId": "arn:aws:cloudformation:us-east-1:404545384114:stack/hiv-gnetii-0217653-001-001-LaunchTplStack/adaafc20-27d7-11ee-83b6-0add2cf4754b"
}
{
    "StackId": "arn:aws:cloudformation:us-east-1:404545384114:stack/hiv-gnetii-0217653-001-001-BatchStack/ba699e80-27d7-11ee-9636-0ec67d5da3f3"
}
  ```

Once you create the environment, be sure to create a new config file to https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master/workflow_options
This config file should contain the job queue ARN. Example 

```
Amazon Resource Name (ARN)
arn:aws:batch:us-east-1:404545384114:job-queue/default-hiv-gnetii-0217653-001-001
```

## Contact
Reach out to Jesse Marks (jmarks@rti.org) for assistance.
