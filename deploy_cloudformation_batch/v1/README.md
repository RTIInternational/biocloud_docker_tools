# Deploying a new Batch stack
This docker image was created to be used interactively. Login, configure your AWS environment, then deploy the batch environment using the wiki guidance provided at
 https://github.com/RTIInternational/bioinformatics/wiki/Cromwell-Cloud-Deployment#aws-cli---create-new-batch-queue

<br><br>

**example**
```
# start interactive mode
docker run -it deploy_cloudformation_batch bash

# configure credentials by running "aws configure".
aws configure
  #AWS Access Key ID [None]:
  #AWS Secret Access Key [None]:
  #Default region name [None]:
  #Default output format [None]:
  
# verify configuration by listing S3 buckets  
aws s3 ls
  #2021-08-10 21:02:09 agc-404545384114-us-east-1
  #2020-02-26 15:05:01 rti-alcohol
  #2020-11-20 17:36:18 rti-cannabis
  #2017-10-13 13:23:33 rti-common
  #...
  
# create environment
bash /opt/deploy-cloudformation-batch.sh \
  --projectNumber 0217694.000.001 \
  --projectShortName "hmagma-nicotine" \
  --cpuMax 500 \
  --stackName cromwell-64-7b7bfb4
  
  #Launch Template ARN: {
  #    "StackId": "arn:aws:cloudformation:us-east-1:404545384114:stack/hmagma-nicotine-0217694-000-001-LaunchTplStack/f801a320-82ae-11ec-8821-0a49dc182711"
  #}
  #{
  #    "StackId": "arn:aws:cloudformation:us-east-1:404545384114:stack/hmagma-nicotine-0217694-000-001-BatchStack/04e5cee0-82af-11ec-bdac-0a585512c3c3"
  #}
  #{
  #    "Version": 1,
  #    "Tier": "Standard"
  #}
  #{
  #    "Version": 1,
  #    "Tier": "Standard"
  #}
  ```
