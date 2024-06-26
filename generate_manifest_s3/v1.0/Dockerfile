FROM ubuntu:20.04
# FROM --platform=linux/amd64 ubuntu:20.04
LABEL description='Generate manifest of S3 objects'
LABEL maintainer='Stephen Hwang <shwang@rti.org>'
LABEL description='Use to create a TSV manifest of S3 objects in designated bucket; includes checksum/etags, file sizes'
LABEL software-website="https://github.com/aws/aws-cli"
LABEL software-version="v2"
LABEL license="https://github.com/aws/aws-cli?tab=License-1-ov-file"
LABEL reference="https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"

ARG DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /opt
RUN mkdir /opt/output

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3-pip \
    curl \
    unzip \
    libc6-dev

# Copy necessary files
COPY ./requirements.txt /opt/
COPY ./*.sh /opt/
COPY ./*.py /opt/

# Install dependencies
RUN python3.9 -m pip install --no-cache-dir -r requirements.txt

# Install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip

# Cleanup
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Make scripts executable
RUN chmod u+x /opt/*.sh
RUN chmod u+x /opt/*.py

# Expose port
EXPOSE 80