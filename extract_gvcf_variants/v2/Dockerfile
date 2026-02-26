# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

#### Install general packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        wget \
        less \
        unzip \
        cpanminus

# Install python3, pip, and module requests
RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install --upgrade pip
RUN pip3 install requests

#### Install PERL modules ####
RUN cpanm install JSON

#### Install plink2 ####
ENV DEBIAN_FRONTEND=noninteractive
RUN wget https://s3.amazonaws.com/plink2-assets/alpha5/plink2_linux_x86_64_20240105.zip \
    && unzip plink2_linux_x86_64_20240105.zip -d /plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20240105.zip plink_tmp
ENV PATH=pkg-config:$PATH:/opt/
RUN rm -Rf /var/lib/apt/lists/*

#### Add pipeline config files
RUN mkdir -p /pipeline/config
ADD config/* /pipeline/config/

#### Add scripts
RUN mkdir -p /pipeline/scripts
ADD scripts/* /pipeline/scripts/
RUN chmod 755 /pipeline/scripts/*

ENTRYPOINT [ "/pipeline/scripts/entrypoint.sh" ]
