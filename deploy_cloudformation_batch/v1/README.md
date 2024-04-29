# AWS Batch Environment Setup for WDL workflows
This script simplifies the creation of a new job queue and compute environment within AWS Batch for executing WDL workflows.
It leverages Launch Templates and Batch Compute Stacks to automate the deployment process based on existing infrastructure as a template.

We use AWS Batch to facilitate the execution of our WDL workflows.
Each project/analysis requires that compute time is charged to the appropriate project.
Thus, for each analysis using WDL we have to create an appropriate job queue (if it doesn't already exist).

This Docker was inspired by the wiki [Cromwell Cloud Deployment](https://github.com/RTIInternational/bioinformatics/wiki/Cromwell-Cloud-Deployment).


## Prerequisites
- An AWS account with proper permissions to create CloudFormation stacks and Batch resources.
- The [Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for programmatic access to the AWS account (used to configure the AWS CLI).
- Docker (obviously)

<br>


# Usage
This script was created to be used in an interactive Docker container.
1. Login to the Docker container
2. Configure your AWS environment
3. Then deploy the batch environment using the `deploy_cloudformation_batch.sh` script.
 
<br>

**example**
```bash
# start interactive mode
$ docker run -it rtibiocloud/deploy_cloudformation_batch:v1_e7476c4 bash

# Enter your AWS Access Key ID and Secret Access Key when prompted.
# Be sure to specify JSON!
$ aws configure

# verify configuration by listing S3 buckets  
$ aws s3 ls
  
# create Batch job queues
$ bash /opt/deploy-cloudformation-batch.sh \
  --projectNumber <project_number> \
  --projectShortName <project_short_name>
```
- Replace `<project_number>` with your project's charge code using periods as delimiters (e.g., 0217653.001.001).
- Replace <project_short_name> with a descriptive name for your project (e.g., "Addiction GNetii R01").

<br>

# Updating Workflow Options
The script will create two job queues by default:
- **Default Queue (Spot Instances):** Uses cost-effective spot instances when the tasks is not super time-sensitive.
- **Priority Queue (On-Demand Instances)**: Uses more reliable on-demand instances for faster execution, though at a premium.

To utilize these queues in your workflows, update the `workflow_options` folder within the [biocloud_gwas_workflows](https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master) repository.<br>
In particular, you need to include add a separate JSON file for each corresponding job queue you created so you and others can utilize these job queues for your WDL workflows.

<br>

**example**
1. Create `spot/0217734.001.001_dana_hancock_addiction_gnetii.json` that contains the ARN for the default job queue:
```json
{
    "default_runtime_attributes": {
      "queueArn": "arn:aws:batch:us-east-1:404545384114:job-queue/default-Addiction-GNetii-R01-0217734-001-001"
    }
}
```
2. Create `on_demand/0217734.001.001_dana_hancock_addiction_gnetii.json` that contains the ARN for the priority job queue:
```json
{
    "default_runtime_attributes": {
      "queueArn": "arn:aws:batch:us-east-1:404545384114:job-queue/priority-Addiction-GNetii-R01-0217734-001-001"
    }
}
```

### Finding the ARN
The ARN (Amazon Resource Name) for each queue can be found by navigating to the AWS Batch console, selecting the job queue, and locating the "ARN" field within the details.

<br>

# Contact
Reach out to Jesse Marks (jmarks@rti.org) for assistance.
