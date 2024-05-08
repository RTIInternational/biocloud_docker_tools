
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
RUN conda install -y conda-forge::xlsx2csv
RUN conda install -c conda-forge -y cryptography=42.0.4
RUN conda install -y conda-forge::paramiko

# Install t1dgrs2 and dependencies
RUN conda install -c conda-forge -y setuptools=67.6.1
RUN conda install -c bioconda -y t1dgrs2

# Add supporting files for t1dgrs2
RUN mkdir /t1dgrs2
RUN mkdir /temp
RUN cd /temp
RUN git clone https://github.com/t2diabetesgenes/t1dgrs2.git \
    && cp /t1dgrs2/data/input/* /t1dgrs2/
RUN rm -rf /temp
ADD t1dgrs2_settings.yml /t1dgrs2/
ADD t1dgrs2_hg19_variants.tsv /t1dgrs2/
ADD hla_variants.txt /t1dgrs2/
ADD non_hla_variants.txt /t1dgrs2/

#### Install plink1.9 ####
RUN conda install -c bioconda -y plink

#### Install PERL modules ####
RUN cpanm install JSON

#### Install custom scripts ####
# Add pipelien config files
ADD t1dgrs2_pipeline.json /opt/
ADD t1dgrs2_pipeline_sample.json /opt/
ADD t1dgrs2_pipeline_export.json /opt/
ADD t1dgrs2_pipeline_no_download.json /opt/
ADD t1dgrs2_tasks.json /opt/
# Add scripts
ADD entrypoint.sh /opt/
ADD run_pipeline.py /opt/
ADD download_gvcfs_from_s3.py /opt/
ADD filter_gvcfs_by_consent.sh /opt/
ADD batch_calculate_t1dgrs2.py /opt/
ADD extract_gvcf_variants.pl /opt/
ADD generate_file_for_export.pl /opt/
ADD merge_results_files.sh /opt/
ADD sftp_results.py /opt/
# Change permissions
RUN chmod 755 /opt/entrypoint.sh
RUN chmod 755 /opt/run_pipeline.py
RUN chmod 755 /opt/download_gvcfs_from_s3.py
RUN chmod 755 /opt/filter_gvcfs_by_consent.sh
RUN chmod 755 /opt/batch_calculate_t1dgrs2.py
RUN chmod 755 /opt/extract_gvcf_variants.pl
RUN chmod 755 /opt/generate_file_for_export.pl
RUN chmod 755 /opt/merge_results_files.sh
RUN chmod 755 /opt/sftp_results.py

WORKDIR /data
RUN chown -R docker:staff /data

ENTRYPOINT [ "/opt/entrypoint.sh" ]
