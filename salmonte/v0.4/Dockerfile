##################### Set Inital Image to work from ############################
FROM ubuntu:18.04


##################### Add Container Labels #####################################
LABEL maintainer="Jesse Marks <jmarks@rti.org>"
LABEL software="SalmonTE"
LABEL software.version="0.4"
LABEL website="https://github.com/LiuzLab/SalmonTE"
LABEL description="Pipeline for the quantification of TEs from RNA-seq data."



##################### Defaults ##############################
# Set a default user. Available via runtime flag `--user docker` 
# Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
# User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd docker \
    && mkdir /home/docker \
    && chown docker:docker /home/docker \
    && addgroup docker staff

# Don't print "debconf: unable to initialize frontend: Dialog" messages
ARG DEBIAN_FRONTEND=noninteractive 


##################### Install System Dependencies ##############################
RUN echo 'deb http://mirror.math.princeton.edu/pub/ubuntu/ bionic main' >> /etc/apt/sources.list \
    && apt update \
    && apt install -y --no-install-recommends \
        git \
        vim-tiny \
        cmake \
        zlib1g-dev \
	dirmngr \
	software-properties-common \
        build-essential \
        ca-certificates \
        wget \
	locales \
	openssl \
	build-essential \
	libssl-dev \
	libffi-dev \
	&& rm -rf /var/lib/apt/lists/*

# Configure default locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Configure default locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

##################### Install R ##############################

# Add R repo to get R 3.6.1
# Install littler, and create a link for littler in /usr/local/bin
# Set a default CRAN repo, and make sure littler knows about it
ENV R_BASE_VERSION 3.6.1-3bionic


RUN add-apt-repository -y ppa:marutter/c2d4u3.5 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        cpp \
        libgirepository-1.0-1 \
        libglib2.0-0 \
        libelf1 \
        libssl-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libmpx0 \
        curl \
        perl-base \
        gpg-agent \
        libxrender1 

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-upgrade r-base-core=${R_BASE_VERSION}
RUN apt-get install -y --no-install-recommends --no-upgrade r-recommended=${R_BASE_VERSION} \
    r-base=${R_BASE_VERSION} \
    r-base-dev=${R_BASE_VERSION} \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'install.packages(c("tidyverse", "scales", "WriteXLS", "BiocManager"))' \
    && Rscript -e 'BiocManager::install("DESeq2", version= "3.10")'
# note that I couldn't get DESeq2 version3.8  to install. It required R3.5 but I couldn't get that to install


##################### Install Python ##############################
# Install python3 and packages
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	python3 \
	python3-pip \
	python3-dev \
	python3-venv \
	python3-wheel \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt clean

RUN pip3 install setuptools
RUN pip3 install wheel snakemake docopt pandas --user


##################### Install SalmonTE ##############################

RUN wget https://github.com/LiuzLab/SalmonTE/archive/v0.4.tar.gz \
    && tar -xvzf v0.4.tar.gz \
    && rm v0.4.tar.gz \
    && mv SalmonTE-0.4 /opt/


############################ Final system configurations ################################

RUN mkdir /data/ 

WORKDIR /data/

ENV PATH="/opt/SalmonTE-0.4/:${PATH}"

# hyperlink to tool in our approved directory structure
RUN cd /opt/ && ln -s SalmonTE-0.4/SalmonTE.py

# default help command
CMD  ["python3", "/opt/SalmonTE.py"]
