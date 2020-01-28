
# Base image
FROM ubuntu:18.04

# Maintainer and author
LABEL maintainer="Bryan Quach <bquach@rti.org>"

#### Basic Ubuntu setup ####

# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group and make home directory 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

ENV DEBIAN_FRONTEND noninteractive
    
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
    && apt-get update \ 
    && apt-get install -y --no-install-recommends \
        dirmngr \
        software-properties-common \
        lsb-release \
        ed \
        less \
        locales \
        vim \
        wget \
        ca-certificates \
        fonts-texgyre \
        make \
        libglib2.0 \
    && rm -rf /var/lib/apt/lists/*

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Add R repo to get more R versions
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
# Install stringr to make dococt install (from source) easier
ENV R_BASE_VERSION 3.6.1-3bionic
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cpp \
        libpcre2-dev \
        libthai0 \
        liblzma-dev \
        libgirepository-1.0-1 \
        libelf1 \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libmpx2 \
        curl \
        perl-base \
        gpg-agent \
        libxrender1 \
        libopenblas-base
        
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-upgrade r-base-core=${R_BASE_VERSION}
RUN apt-get install -y --no-install-recommends --no-upgrade r-recommended=${R_BASE_VERSION} \
    r-base=${R_BASE_VERSION} \
    r-base-dev=${R_BASE_VERSION} \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

#### Install PySAM ####    
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python-dev \
        python-pip \
    && pip install setuptools \
    && pip install wheel \
    && pip install pysam \
    && pip install HTSeq \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

#### Install DEXSeq ####    
#Install packages from CRAN and bioconductor:
RUN Rscript -e 'install.packages(c("BiocManager"));' \
    && Rscript -e 'BiocManager::install(version = "3.9", ask = F);'
RUN Rscript -e 'BiocManager::install(c("DEXSeq", "tximport"), version = "3.9");'
RUN ln -s /usr/local/lib/R/site-library/DEXSeq/python_scripts/dexseq_count.py /opt/dexseq_count.py \
    && ln -s /usr/local/lib/R/site-library/DEXSeq/python_scripts/dexseq_prepare_annotation.py /opt/dexseq_prepare_annotation.py
WORKDIR /

ENV PATH=pkg-config:$PATH:/opt/

CMD ["ls", "-1", "/opt"]