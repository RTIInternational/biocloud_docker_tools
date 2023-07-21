#!/bin/bash

set -e

projectNumber=""
projectShortName=""

# Optional Parameters
stackName="" # Default = gwfcore03
cpuMax="" # Default = 100
profile="" # Default = default

while [ "$1" != "" ]; 
do
    case $1 in
        --projectNumber )      shift
                        projectNumber=$1
                        ;;
        --projectShortName )   shift
                        projectShortName=$1
                        ;;
        --cpuMax )      shift
                        cpuMax=$1
                        ;;
        --stackName )   shift
                        stackName=$1
                        ;;
        --profile )      shift
                        profile=$1
                        ;;
    esac
    shift
done

if [ -z "$stackName" ]
then
    stackName="gwfcore03"
fi

if [ -z "$cpuMax" ]
then
    cpuMax="100"
fi

if [ -z "$profile" ]
then
    profile="default"
fi

listOfStacks=$(aws cloudformation list-stacks --profile ${profile})
listOfStacksNames=$(echo $listOfStacks | jq -r .StackSummaries | jq -r .[] | jq -r .StackName)
for i in $listOfStacksNames
do
    if [[ "$i" == *"$stackName-BatchStack"* ]]; then
        batchStackName=$i
    fi
done

# Get BatchstackDetails using AWS CLI
BatchstackDetails=$(aws cloudformation describe-stacks --stack-name "${batchStackName}" --profile "${profile}")

# Extract relevant information from BatchstackDetails using jq
vpcID=$(echo "$BatchstackDetails" | jq -r '.Stacks[].Parameters[] | select(.ParameterKey == "VpcId") | .ParameterValue')
vpcSubnetIDs=$(echo "$BatchstackDetails" | jq -r '.Stacks[].Parameters[] | select(.ParameterKey == "SubnetIds") | .ParameterValue')
batchServiceRoleARN=$(echo "$BatchstackDetails" | jq -r '.Stacks[].Parameters[] | select(.ParameterKey == "BatchServiceRoleArn") | .ParameterValue')
ec2InstanceProfileARN=$(echo "$BatchstackDetails" | jq -r '.Stacks[].Parameters[] | select(.ParameterKey == "Ec2InstanceProfileArn") | .ParameterValue')
spotFleetRoleARN=$(echo "$BatchstackDetails" | jq -r '.Stacks[].Parameters[] | select(.ParameterKey == "SpotFleetRoleArn") | .ParameterValue')

# Create Launch Template that uses charge code on EBS volumes
launchTemplateARN=$(aws cloudformation create-stack \
    --stack-name "${projectShortName// /-}-${projectNumber//./-}-LaunchTplStack" \
    --template-url "https://cromwell-templates.s3.amazonaws.com/gwfcore03/templates/gwfcore/gwfcore-launch-template-20230720.yaml" \
    --parameters ParameterKey=Namespace,ParameterValue="${projectShortName// /-}-${projectNumber//./-}" \
                ParameterKey=LaunchTemplateNamePrefix,ParameterValue="${projectShortName// /-}-${projectNumber//./-}" \
                ParameterKey=DockerStorageVolumeSize,ParameterValue=100 \
                ParameterKey=ProjectNumber,ParameterValue="$projectNumber" \
    --tags Key="project-number",Value="$projectNumber" \
    --profile ${profile})

echo "Launch Template ARN: $launchTemplateARN"
# Need time for the Launch Template to actually have an ID.
sleep 20
launchTemplateInfo=$(aws cloudformation describe-stacks --stack-name $(echo $launchTemplateARN | jq -r .StackId))
launchTemplateID=$(echo $launchTemplateInfo | jq -r .Stacks | jq -r .[] | jq -r .Outputs | jq -r .[] | jq -r .OutputValue)

arrSubnets=(${vpcSubnetIDs//,/ })


# Create Batch compute stack that creates EC2 instances with charge code tag
# other optional parameters: BatchComputeInstanceTypes, BatchSpotBidPercentage, and FSxSubnetId
aws cloudformation create-stack \
    --stack-name "${projectShortName// /-}-${projectNumber//./-}-BatchStack" \
    --template-url https://cromwell-templates.s3.amazonaws.com/gwfcore03/templates/gwfcore/gwfcore-batch-template-20230720.yaml \
    --parameters ParameterKey=Namespace,ParameterValue="${projectShortName// /-}-${projectNumber//./-}" \
		ParameterKey=LaunchTemplateId,ParameterValue="$launchTemplateID" \
                ParameterKey=VpcId,ParameterValue="$vpcID" \
                ParameterKey=SubnetIds,ParameterValue="${arrSubnets[1]}" \
                ParameterKey=DefaultCEMinvCpus,ParameterValue="0" \
                ParameterKey=DefaultCEMaxvCpus,ParameterValue="$cpuMax" \
                ParameterKey=PriorityCEMinvCpus,ParameterValue="0" \
                ParameterKey=PriorityCEMaxvCpus,ParameterValue="$cpuMax" \
                ParameterKey=BatchServiceRoleArn,ParameterValue="$batchServiceRoleARN" \
                ParameterKey=Ec2InstanceProfileArn,ParameterValue="$ec2InstanceProfileARN" \
                ParameterKey=SpotFleetRoleArn,ParameterValue="$spotFleetRoleARN" \
                ParameterKey=ProjectNumber,ParameterValue="$projectNumber" \
    --tags Key="project-number",Value="$projectNumber" \
    --profile ${profile}

# Add launch template required SSM parameters for this namespace (note: delete existing parameters if already exist!)
s3Rooturl=$(aws ssm get-parameter --name /gwfcore/$stackName/installed-artifacts/s3-root-url --query 'Parameter.Value' --output text)
#sharedFileSystem=$(aws ssm get-parameter --name /gwfcore/$stackName/efs-shared-file-system --query 'Parameter.Value' --output text)

aws ssm put-parameter --name /gwfcore/"${projectShortName// /-}-${projectNumber//./-}"/installed-artifacts/s3-root-url \
    --value "$s3Rooturl" \
    --type String

#aws ssm put-parameter --name /gwfcore/"${projectShortName// /-}-${projectNumber//./-}"/efs-shared-file-system \
#    --value "$sharedFileSystem" \
#    --type String
