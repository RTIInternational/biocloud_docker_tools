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
 
<br><br>

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
- Replace <project_number> with your project's charge code (e.g., 0217653.001.001).
- Replace <project_short_name> with a descriptive name for your project (e.g., "Addiction GNetii R01").

<br>

# Updating Workflow Options
The script will create two job queues by default:
- A default queue using spot EC2 instances for cost-effective compute when it's not super time sensitive.
- A priority queue using on-demand EC2 instances for urgent jobs.

To utilize these queues in your workflows, update the workflow_options folder within the [biocloud_gwas_workflows](https://github.com/RTIInternational/biocloud_gwas_workflows/tree/master) repository.
Add separate JSON files with descriptive names, each containing the corresponding job queue ARN.
See [Finding the ARN](/#finding-the-arn) below.

**Example:**
For the example above, create two JSON files:
* `spot/0217734.001.001_dana_hancock_addiction_gnetii.json`: This file would contain the ARN for the default queue (spot instances).
* `on-demand/0217734.001.001_dana_hancock_addiction_gnetii.json`: This file would contain the ARN for the priority queue (on-demand instances).


<br>


### Finding the ARN:

The ARN (Amazon Resource Name) for each queue can be found by navigating to the AWS Batch console, selecting the job queue, and locating the "ARN" field within the details.
Using the sample above, the ARN for the default job queue above would be:

```
arn:aws:batch:us-east-1:404545384114:job-queue/default-Addiction-GNetii-R01-0217734-001-001
```

<br>

# Contact
Reach out to Jesse Marks (jmarks@rti.org) for assistance.
