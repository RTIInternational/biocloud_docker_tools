# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

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
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

#### Install Eagle ####
RUN wget https://storage.googleapis.com/broad-alkesgroup-public/Eagle/downloads/Eagle_v2.4.1.tar.gz --no-check-certificate \
    && tar -xvzf Eagle_v2.4.1.tar.gz \
    && rm Eagle_v2.4.1.tar.gz \
    && mv Eagle_v2.4.1 /Eagle

WORKDIR /

ENV PATH=$PATH:/Eagle
