# Docker image name: multiqc_extract
# Sample build: docker build -t multiqc_extract:v1 .
# Sample run: docker run -it -v $PWD:/data multiqc_extract:v1.0 bash

# FROM arm64v8/r-base
FROM r-base

LABEL maintainer=dnwilliams@rti.org

RUN apt update && apt install -y jq && jq --version

# Add scripts to make it run
ADD unzip_extract_stats.sh /

# Add to /opt folder
RUN mv unzip_extract_stats.sh /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/unzip_extract_stats.sh

# Set wrkdir
RUN mkdir /data
COPY . /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/