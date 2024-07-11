# Use the official Google Cloud SDK image as the base image
FROM --platform=linux/amd64 google/cloud-sdk:latest
# FROM google/cloud-sdk:latest
LABEL description='Generate manifest of objects in GCS bucket using Google service account'
LABEL maintainer='Stephen Hwang <shwang@rti.org>'
LABEL software-website="https://github.com/aws/aws-cli"
LABEL software-version="v2"
LABEL license="https://github.com/aws/aws-cli?tab=License-1-ov-file"
LABEL reference="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"

# Install necessary tools, AWS CLI, Python, and clean up 
RUN apt-get update && \
    apt-get install -y unzip curl && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /opt

# Copy the local code to the container's working directory
COPY ./opt/ /opt/

# Copy requirements.txt and install dependencies
RUN python3.9 -m pip install --no-cache-dir -r requirements.txt

# Make sure the scripts are executable
RUN chmod +x /opt/*.sh
