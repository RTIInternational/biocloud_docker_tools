FROM rocker/r-ubuntu:20.04

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains an in-house script written to extract several key stats of interest from a MultiQC run coming off of a FastQC analysis."

RUN apt update
RUN apt install -y vim

# Installing R package to extract JSON info
RUN R -e "install.packages(c('jsonlite','getopt','knitr'))"

# Add scripts to make it run
ADD unzip_extract_stats.R /

# Add to /opt folder
RUN mv unzip_extract_stats.R /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/unzip_extract_stats.R

# Set wrkdir
RUN mkdir /data
COPY ./*.zip /data
WORKDIR /data

# Add to environment
ENV PATH $PATH:/opt/
