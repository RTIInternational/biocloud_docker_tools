# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Stephanie Giamberardino <sgiamberardino@rti.org>"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker`
# Add user to 'staff' group and make home directory
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
    && rm -rf /var/lib/apt/lists/*

#### Install minimac4 ####
RUN wget https://github.com/statgen/Minimac4/releases/download/v4.1.6/minimac4-4.1.6-Linux-x86_64.sh --no-check-certificate
RUN chmod +x minimac4-4.1.6-Linux-x86_64.sh
RUN ./minimac4-4.1.6-Linux-x86_64.sh --skip-license

WORKDIR /

ENV PATH=$PATH:/bin

