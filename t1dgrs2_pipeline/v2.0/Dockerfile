# Base image
FROM ubuntu:22.04

# Maintainer and author
LABEL maintainer="Nathan Gaddis <ngaddis@rti.org>"

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group and make home directory 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

#### Install general packages
RUN rm -Rf /var/lib/apt/lists/*
RUN apt-get update \
    && apt-get install -y \
        curl \
        wget \
        unzip \
        cpanminus \
        git \
        fonts-texgyre \
        libatlas-base-dev

ENV PATH /opt/conda/bin:$PATH

# Install miniconda3
RUN set -x && \
    wget "https://repo.anaconda.com/miniconda/Miniconda3-py312_24.3.0-0-Linux-x86_64.sh" -O miniconda.sh -q && \
    echo "96a44849ff17e960eeb8877ecd9055246381c4d4f2d031263b63fa7e2e930af1 miniconda.sh" > shasum && \
    sha256sum --check --status shasum && \
    mkdir -p /opt && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh shasum && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

# Install python
RUN conda install -c anaconda -y python=3.11
RUN ln -s /root/miniconda3/bin/python3.11 /usr/bin/python

# Install python packages
RUN conda install -y conda-forge::boto3
RUN conda install -c conda-forge -y cryptography=42.0.4
RUN conda install -y conda-forge::paramiko
RUN conda install -y conda-forge::pandas
RUN conda install -y conda-forge::openpyxl

# Install t1dgrs2 and dependencies
RUN conda install -c conda-forge -y setuptools=67.6.1
RUN conda install -c bioconda -y t1dgrs2

#### Install plink1.9 ####
RUN conda install -c bioconda -y plink

#### Install PERL modules ####
RUN cpanm install JSON

# Add pipeline inputs
RUN mkdir -p /pipeline/inputs
ADD pipeline_inputs/* /pipeline/inputs/

# Add pipeline config files
RUN mkdir -p /pipeline/config
ADD pipeline_config/* /pipeline/config/

#### Install custom scripts ####
# Add scripts
ADD scripts/entrypoint.sh /opt/
ADD scripts/run_pipeline.py /opt/
ADD scripts/download_gvcfs_from_revvity_sftp.py /opt/
ADD scripts/batch_extract_gvcf_variants.py /opt/
ADD scripts/extract_gvcf_variants.pl /opt/
ADD scripts/generate_file_for_export.pl /opt/
ADD scripts/sftp_results.py /opt/
# Change permissions
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/run_pipeline.py
RUN chmod 755 /opt/download_gvcfs_from_revvity_sftp.py
RUN chmod 755 /opt/batch_extract_gvcf_variants.py
RUN chmod 755 /opt/extract_gvcf_variants.pl
RUN chmod 755 /opt/generate_file_for_export.pl
RUN chmod 755 /opt/sftp_results.py

WORKDIR /data
RUN chown -R docker:staff /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]

