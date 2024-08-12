FROM rocker/r-ubuntu:22.04

LABEL maintainer="David Williams <dnwilliams@rti.org>"
LABEL description="This Docker image contains an in-house script written to generate a file manifest of projects in Seven Bridges."
LABEL base-image="rocker/r-ubuntu:20.04"
LABEL software-version="1.0"

# Install vim and required packages for R libraries
RUN apt update && apt install -y \
    libcurl4-openssl-dev \
    libssl-dev \ 
    vim

# Install R libraries
RUN Rscript -e 'install.packages(c("dplyr","stringr", "lubridate", "openxlsx", "sevenbridges2", "getopt"))'

# Add scripts to make it run
ADD generate_manifest_sevenbridges.R /

# Add to /opt folder
RUN mv generate_manifest_sevenbridges.R /opt/

# Change permissions to make things exectuable
RUN chmod u+x /opt/generate_manifest_sevenbridges.R

# Set wrkdir
RUN mkdir /data
WORKDIR /data

# Add to environment
ENV PATH=$PATH:/opt/
