#!/bin/bash

set -e

projectNumber=""
projectShortName=""
# Default = 100
cpuMax=""
# Default = cromwell-54
stackName=""
# Default = default
profile=""

# Get from master stack in stackName
launchTemplateID=""
vpcID=""
vpcSubnetIDs=""
batchServiceRoleARN=""
ec2InstanceProfileARN=""
spotFleetRoleARN=""

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
    stackName="cromwell-64-7b7bfb4"
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

BatchstackDetails=$(aws cloudformation describe-stacks --stack-name ${batchStackName} --profile ${profile})
declare -a stackDetailsDict
BatchStackDetailsDict=$(echo $BatchstackDetails | jq -r .Stacks | jq -r .[] | jq -r .Parameters | jq -r .[] | jq -r .[])
eval "arr=($BatchStackDetailsDict)"
for ((index=0; index <= ${#arr[@]}; ++index))
do
    position=$(( $index + 1 ))
    case ${arr[$index]} in
        # LaunchTemplateId )
        #                 launchTemplateID=${arr[$position]}
        #                 ;;
        VpcId )
                        vpcID=${arr[$position]}
                        ;;
        SubnetIds )
                        vpcSubnetIDs=${arr[$position]}
                        ;;
        BatchServiceRoleArn )
                        batchServiceRoleARN=${arr[$position]}
                        ;;
        Ec2InstanceProfileArn )
                        ec2InstanceProfileARN=${arr[$position]}
                        ;;
        SpotFleetRoleArn )
                        spotFleetRoleARN=${arr[$position]}
                        ;;
    esac
done

# Create Launch Template that uses charge code on EBS volumes
launchTempletARN=$(aws cloudformation create-stack \
    --stack-name "${projectShortName// /-}-${projectNumber//./-}-LaunchTplStack" \
    --template-url https://cromwell-templates.s3.amazonaws.com/cromwell-64-7b7bfb4/templates/gwfcore/gwfcore-launch-template-projectNumbers.template.yaml \
    --parameters ParameterKey=Namespace,ParameterValue="${projectShortName// /-}-${projectNumber//./-}" \
                ParameterKey=LaunchTemplateNamePrefix,ParameterValue="${projectShortName// /-}-${projectNumber//./-}" \
                ParameterKey=DockerStorageVolumeSize,ParameterValue=100 \
                ParameterKey=ProjectNumber,ParameterValue="$projectNumber" \
    --tags Key="project-number",Value="$projectNumber" \
    --profile ${profile})

echo "Launch Template ARN: $launchTempletARN"
# Need time for the Launch Template to actually have an ID.
sleep 20
launchTemplateInfo=$(aws cloudformation describe-stacks --stack-name $(echo $launchTempletARN | jq -r .StackId))
launchTemplateID=$(echo $launchTemplateInfo | jq -r .Stacks | jq -r .[] | jq -r .Outputs | jq -r .[] | jq -r .OutputValue)

arrSubnets=(${vpcSubnetIDs//,/ })

# Create Batch compute stack that creates EC2 instances with charge code tag
aws cloudformation create-stack \
    --stack-name "${projectShortName// /-}-${projectNumber//./-}-BatchStack" \
    --template-url https://cromwell-templates.s3.amazonaws.com/cromwell-64-7b7bfb4/templates/gwfcore/gwfcore-batch.updated.template.yaml \
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

# Add launch template required SSM paramiters for this namespace
s3Rooturl=$(aws ssm get-parameter --name /gwfcore/$stackName/installed-artifacts/s3-root-url --query 'Parameter.Value' --output text)
sharedFileSystem=$(aws ssm get-parameter --name /gwfcore/$stackName/efs-shared-file-system --query 'Parameter.Value' --output text)

aws ssm put-parameter --name /gwfcore/"${projectShortName// /-}-${projectNumber//./-}"/installed-artifacts/s3-root-url \
    --value "$s3Rooturl" \
    --type String

aws ssm put-parameter --name /gwfcore/"${projectShortName// /-}-${projectNumber//./-}"/efs-shared-file-system \
    --value "$sharedFileSystem" \
    --type String

