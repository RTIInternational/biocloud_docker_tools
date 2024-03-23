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

#### Install PERL modules ####
RUN cpanm install JSON

#### Install plink2 ####
ENV DEBIAN_FRONTEND noninteractive
RUN wget https://s3.amazonaws.com/plink2-assets/alpha5/plink2_linux_x86_64_20240105.zip \
    && unzip plink2_linux_x86_64_20240105.zip -d /plink_tmp \
    && cp /plink_tmp/plink2 /opt/ \
    && rm -rf plink2_linux_x86_64_20240105.zip plink_tmp
ENV PATH=pkg-config:$PATH:/opt/
RUN rm -Rf /var/lib/apt/lists/*

#### Install custom scripts ####
# Add scripts
ADD extract_gvcf_variants.pl /opt/
ADD entrypoint.sh /opt/
# Change permissions
RUN chmod 755 /opt/extract_gvcf_variants.pl
RUN chmod 755 /opt/entrypoint.sh

# Add built-in variant lists
RUN mkdir /data
ADD t1dgrs2_hg19_variants.tsv /data/

WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

