##################### Set Inital Image to work from ############################
FROM python:3.9.10-slim-buster

##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL description="A script to archive and delete files recursively in S3."

# Install System Dependencies
RUN apt-get update && apt-get install -y \
    vim \
    less \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install boto3 argparse datetime pytz

# Copy the script
COPY glacierize.py /opt/

WORKDIR /data

ENTRYPOINT ["python", "/opt/glacierize.py"]
CMD ["-h"]
