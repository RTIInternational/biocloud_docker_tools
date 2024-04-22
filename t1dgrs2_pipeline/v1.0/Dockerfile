
# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Arguments
ARG PATH="/root/miniconda3/bin:${PATH}"

#### Install general packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        curl \
        wget \
        unzip \
        cpanminus

# Install miniconda to /miniconda
ENV PATH="/root/miniconda3/bin:${PATH}"
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN mkdir /root/.conda
RUN bash Miniconda3-latest-Linux-x86_64.sh -b
RUN rm -f Miniconda3-latest-Linux-x86_64.sh
RUN conda update -y conda

# Install python
RUN conda install -c anaconda -y python=3.11

# Install python packages
RUN conda install -y conda-forge::boto3
RUN conda install -y conda-forge::xlsx2csv

# Install t1dgrs2 and dependencies
RUN conda install -c conda-forge -y setuptools=67.6.1
RUN conda install -c bioconda -y t1dgrs2
RUN mkdir /t1dgrs2
ADD t1dgrs2_settings.yml /t1dgrs2/
ADD t1dgrs2/data/input/* /t1dgrs2/
ADD t1dgrs2_hg19_variants.tsv /t1dgrs2/

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
# Add config files
ADD t1dgrs2_pipeline_step_1.json /opt/
ADD t1dgrs2_pipeline_step_2.json /opt/
ADD t1dgrs2_tasks.json /opt/
# Add scripts
ADD entrypoint.sh /opt/
ADD run_pipeline.py /opt/
ADD download_gvcfs_from_s3.py /opt/
ADD filter_gvcfs_by_consent.sh /opt/
ADD batch_calculate_t1dgrs2.py /opt/
ADD extract_gvcf_variants.pl /opt/
# Change permissions
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/run_pipeline.py
RUN chmod 755 /opt/download_gvcfs_from_s3.py
RUN chmod 755 /opt/filter_gvcfs_by_consent.sh
RUN chmod 755 /opt/batch_calculate_t1dgrs2.py
RUN chmod 755 /opt/extract_gvcf_variants.pl

WORKDIR /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]
