##################### Set Inital Image to work from ############################
FROM python:3.9.10-slim-buster


##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="A script to download results located on S3 from a WDL workflow run"



# Install System Dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    vim \
    less \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN apt-get update && \
    apt-get install -y unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm awscliv2.zip && \
    rm -rf aws

# Install Python packages
RUN pip install boto3 argparse


# Copy the script
COPY download_wdl_results_from_json.py /opt/

WORKDIR /data

ENTRYPOINT ["python", "/opt/download_wdl_results_from_json.py"]
CMD ["-h"]
