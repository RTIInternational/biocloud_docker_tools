# Use the official Google Cloud SDK image as the base image
FROM --platform=linux/amd64 google/cloud-sdk:latest

LABEL description='Generate manifest of objects in GCS bucket using Google service account'
LABEL maintainer='Stephen Hwang <shwang@rti.org>'
LABEL software-website="https://github.com/aws/aws-cli"
LABEL software-version="v2"
LABEL license="https://github.com/aws/aws-cli?tab=License-1-ov-file"
LABEL reference="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"

# Install necessary tools and dependencies, including Python 3.9 dependencies
RUN apt-get update && \
    apt-get install -y unzip curl build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget libncurses5-dev \
    libgdbm-dev libnss3-dev libffi-dev liblzma-dev && \
    apt-get clean

# Download and install Python 3.9 from source
RUN wget https://www.python.org/ftp/python/3.9.7/Python-3.9.7.tgz && \
    tar -xf Python-3.9.7.tgz && \
    cd Python-3.9.7 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    cd .. && \
    rm -rf Python-3.9.7 Python-3.9.7.tgz

# Install pip for Python 3.9
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3.9 get-pip.py && \
    rm get-pip.py

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws

# Set the working directory in the container
WORKDIR /opt

# Copy the local code to the container's working directory
COPY ./opt/ /opt/

# Install python dependencies
RUN python3.9 -m pip install --no-cache-dir -r /opt/requirements.txt

# Make sure the scripts are executable
RUN chmod +x /opt/*.sh